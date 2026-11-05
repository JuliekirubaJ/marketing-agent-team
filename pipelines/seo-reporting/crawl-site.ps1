<#
.SYNOPSIS
  Screaming Frog replacement for the monthly report's site-crawl rows. Crawls one site:
  homepage + every sitemap URL + every internal <a href> found on crawled HTML pages, up to -Max.
  Uses curl.exe for every request: some hosts drop the connection on 404s in a way .NET can't read,
  and curl reports real status codes and timings without following redirects.
  Writes sf\internal_all.csv (one row per URL, SF-like columns), sf\redirect_chains.csv and
  sf\crawl-summary.json (the counts).

  Scope: the site's own host only (www and apex treated as the same site), HTML pages + redirects +
  errors. Images/CSS/JS are not crawled (SF's "unfiltered" count includes them), but every page is
  scanned for insecure http:// resources.

  If a real Screaming Frog internal_all.csv is dropped into sf\, it wins: run this only when sf\ is empty.

  -OutDir defaults to <root>\seo\_exports\<current YYYY-MM>\<site>.

.EXAMPLE
  .\crawl-site.ps1 -Site main
#>
param(
  [Parameter(Mandatory)][string]$Site,
  [string]$OutDir,
  [int]$Max = 3000,
  [double]$DelaySeconds = 0.2,
  [string]$Root
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
$cfg = Get-SeoSite $Root $Site
if (-not $OutDir) { $OutDir = Join-Path (Get-SeoDataDir $Root) ("_exports\" + (Get-Date -Format 'yyyy-MM') + "\$Site") }
$origin = $cfg.Origin
$bareHost = ([uri]$origin).Host -replace '^www\.', ''
$hostRe = '^https?://(www\.)?' + [regex]::Escape($bareHost) + '(/|$)'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36 SEOAuditCrawler'
$tmp = Join-Path $env:TEMP "seo-crawl-$Site"; New-Item -ItemType Directory -Force $tmp | Out-Null
$bodyFile = Join-Path $tmp 'body.html'

function Normalize([string]$href, [string]$base) {
  if (-not $href) { return $null }
  $href = [System.Net.WebUtility]::HtmlDecode($href.Trim())
  if ($href -match '^(mailto:|tel:|javascript:|#|data:)') { return $null }
  # template placeholders leaked into hrefs (e.g. "{{ data.editLink }}") produce hundreds of fake 404s
  if ($href -match '\{\{|\}\}|%7B%7B') { return $null }
  try { $u = [uri]::new([uri]$base, $href) } catch { return $null }
  if ($u.Scheme -notmatch '^https?$') { return $null }
  $s = $u.GetLeftPart([UriPartial]::Query) -replace '#.*$', ''
  if ($s -notmatch $hostRe) { return $null }
  if ($s -match '\.(jpe?g|png|gif|svg|webp|ico|css|js|pdf|zip|mp4|webm|woff2?|ttf|xml|json)(\?|$)') { return $null }
  if ($s -match '[?&](replytocom|share|s)=' -or $s -match '/wp-json/|/feed/?$|/xmlrpc\.php') { return $null }
  return $s
}
function Fetch([string]$u) {
  if (Test-Path $bodyFile) { Remove-Item $bodyFile -Force }
  $w = & curl.exe -s -A $ua --max-time 40 --compressed -o $bodyFile -w '%{http_code}|%{time_total}|%{redirect_url}|%{content_type}|%{size_download}' $u 2>$null
  $p = "$w" -split '\|'
  $body = if ((Test-Path $bodyFile) -and $p[3] -match 'html') { [IO.File]::ReadAllText($bodyFile, [Text.Encoding]::UTF8) } else { '' }
  return @{ code = [int]$p[0]; time = [double]$p[1]; location = $p[2]; ctype = $p[3]; bytes = [int64]$p[4]; body = $body }
}
function M1([string]$h, [string]$re) { $m = [regex]::Match($h, $re); if ($m.Success) { [System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Trim() } else { '' } }

# robots.txt disallow rules for * (to report "blocked by robots", as SF does with that option on)
$robotsRules = @()
$rb = Fetch "$origin/robots.txt"
$robotsText = if ($rb.code -eq 200) { $rb.body + (Get-Content $bodyFile -Raw -ErrorAction SilentlyContinue) } else { '' }
$inStar = $false
foreach ($line in ($robotsText -split "`n")) {
  $t = ($line -replace '#.*$', '').Trim()
  if ($t -match '^(?i)user-agent:\s*(.+)$') { $inStar = ($Matches[1].Trim() -eq '*') }
  elseif ($inStar -and $t -match '^(?i)disallow:\s*(\S+)') { $robotsRules += $Matches[1] }
}
function Is-Blocked([string]$u) { $path = ([uri]$u).PathAndQuery; foreach ($r in $robotsRules) { $rx = '^' + ([regex]::Escape($r) -replace '\\\*', '.*' -replace '\\\$$', '$'); if ($path -match $rx) { return $true } }; return $false }

# seeds: homepage + sitemap URLs
$queue = New-Object System.Collections.Generic.Queue[string]
$seen = New-Object 'System.Collections.Generic.HashSet[string]'
function Enqueue([string]$u) { if ($u -and $seen.Add($u)) { $queue.Enqueue($u) } }
Enqueue "$origin/"
function SitemapUrls([string]$u, [int]$d = 0) {
  if ($d -gt 3) { return }
  $r = Fetch $u; $xml = if (Test-Path $bodyFile) { Get-Content $bodyFile -Raw } else { '' }
  try { $x = [xml]$xml } catch { return }
  if ($x.sitemapindex) { foreach ($s in $x.sitemapindex.sitemap) { SitemapUrls $s.loc ($d + 1) } }
  elseif ($x.urlset) { foreach ($l in $x.urlset.url) { $l.loc.Trim() } }
}
$inSitemap = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($sm in (Get-SitemapCandidates $origin $robotsText)) {
  $found = @(SitemapUrls $sm)
  foreach ($s in $found) { [void]$inSitemap.Add($s); Enqueue $s }
  if ($found.Count) { break }
}

$rows = New-Object System.Collections.Generic.List[object]
$started = Get-Date
# Speed: docs/forum themes can carry ~900 nav links per page, so raw hrefs already seen are skipped,
# and pages are fetched 6 at a time.
$rawSeen = New-Object 'System.Collections.Generic.HashSet[string]'
$retried = New-Object 'System.Collections.Generic.HashSet[string]'
$fetchBlock = {
  param($u, $ua, $file)
  $w = & curl.exe -s -A $ua --max-time 40 --compressed -o $file -w '%{http_code}|%{time_total}|%{redirect_url}|%{content_type}|%{size_download}' $u 2>$null
  $p = "$w" -split '\|'
  $body = if ((Test-Path $file) -and $p[3] -match 'html') { [IO.File]::ReadAllText($file, [Text.Encoding]::UTF8) } else { '' }
  if (Test-Path $file) { [IO.File]::Delete($file) }
  @{ u = $u; code = [int]$p[0]; time = [double]$p[1]; location = $p[2]; ctype = $p[3]; body = $body }
}
$pool = [RunspaceFactory]::CreateRunspacePool(1, 6); $pool.Open()
$fetched = @{}
function Prefetch {
  $batch = @(); $i = 0
  foreach ($q in @($queue.ToArray() | Select-Object -First 6)) {
    if ($fetched.ContainsKey($q) -or (Is-Blocked $q)) { continue }
    $ps = [PowerShell]::Create(); $ps.RunspacePool = $pool
    [void]$ps.AddScript($fetchBlock).AddArgument($q).AddArgument($ua).AddArgument((Join-Path $tmp "b$i.html")); $i++
    $batch += @{ ps = $ps; h = $ps.BeginInvoke() }
  }
  foreach ($b in $batch) { foreach ($o in $b.ps.EndInvoke($b.h)) { $fetched[$o.u] = $o }; $b.ps.Dispose() }
  if ($DelaySeconds -gt 0) { Start-Sleep -Milliseconds ([int]($DelaySeconds * 1000)) }
}
while ($queue.Count -gt 0 -and $rows.Count -lt $Max) {
  if (-not $fetched.ContainsKey($queue.Peek())) { Prefetch }
  $u = $queue.Dequeue()
  if (Is-Blocked $u) {
    $rows.Add([pscustomobject]@{ Address = $u; 'Status Code' = 0; Status = 'Blocked by robots.txt'; Indexability = 'Non-Indexable'; 'Content Type' = ''; 'Response Time' = ''; 'Redirect URL' = ''; 'Title 1' = ''; 'Meta Description 1' = ''; 'H1-1' = ''; 'H1 Count' = 0; 'Canonical Link Element 1' = ''; 'Meta Robots 1' = ''; 'Insecure Resources' = 0; 'In Sitemap' = $inSitemap.Contains($u) })
    continue
  }
  $r = if ($fetched.ContainsKey($u)) { $fetched[$u] } else { Fetch $u }; $fetched.Remove($u)
  # A 5xx / no-response under parallel load can be the host throttling us: retry once, alone, after a
  # pause, before recording it. But do not assume throttling: whole templates can genuinely return 500
  # while still rendering content (check one in a browser before calling it transient).
  if (($r.code -ge 500 -or $r.code -eq 0) -and -not $retried.Contains($u)) { [void]$retried.Add($u); Start-Sleep -Seconds 3; $r = Fetch $u }
  $h = $r.body
  $title = M1 $h '(?is)<title[^>]*>(.*?)</title>'
  $meta = M1 $h '(?is)<meta\s[^>]*name=["'']description["''][^>]*content=["'']([^"'']*)'
  if (-not $meta) { $meta = M1 $h '(?is)<meta\s[^>]*content=["'']([^"'']*)["''][^>]*name=["'']description["'']' }
  $h1s = @([regex]::Matches($h, '(?is)<h1[^>]*>(.*?)</h1>') | ForEach-Object { ([System.Net.WebUtility]::HtmlDecode(($_.Groups[1].Value -replace '<[^>]+>', ' ')) -replace '\s+', ' ').Trim() })
  $canon = M1 $h '(?is)<link\s[^>]*rel=["'']canonical["''][^>]*href=["'']([^"'']+)'
  $robotsMeta = M1 $h '(?is)<meta\s[^>]*name=["'']robots["''][^>]*content=["'']([^"'']*)'
  $insecure = if ($origin -like 'https*') { ([regex]::Matches($h, '(?i)<(img|script|iframe|link|source|video|audio)\b[^>]*\b(src|href)=["'']http://')).Count } else { 0 }
  $status = switch -regex ("$($r.code)") { '^2' { 'OK' } '^3' { 'Redirect' } '^4' { 'Client Error' } '^5' { 'Server Error' } default { 'No Response' } }
  $nonIdx = ($r.code -ne 200) -or ($robotsMeta -match 'noindex') -or ($canon -and ($canon.TrimEnd('/') -ne $u.TrimEnd('/')))
  $rows.Add([pscustomobject]@{
    Address = $u; 'Status Code' = $r.code; Status = $status
    Indexability = if ($nonIdx) { 'Non-Indexable' } else { 'Indexable' }
    'Content Type' = $r.ctype; 'Response Time' = [math]::Round($r.time, 3); 'Redirect URL' = $r.location
    'Title 1' = $title; 'Meta Description 1' = $meta; 'H1-1' = ($h1s | Select-Object -First 1); 'H1 Count' = $h1s.Count
    'Canonical Link Element 1' = $canon; 'Meta Robots 1' = $robotsMeta; 'Insecure Resources' = $insecure; 'In Sitemap' = $inSitemap.Contains($u)
  })
  if ($r.code -ge 300 -and $r.code -lt 400 -and $r.location) { Enqueue (Normalize $r.location $u) }
  if ($h) { foreach ($m in [regex]::Matches($h, '(?is)<a\s[^>]*href=["'']([^"'']+)["'']')) { $raw = $m.Groups[1].Value; if ($raw -match '^https?://' -and -not $rawSeen.Add($raw)) { continue }; Enqueue (Normalize $raw $u) } }
  if ($rows.Count % 100 -eq 0) { Write-Host "  crawled $($rows.Count), queue $($queue.Count)" }
}
$pool.Close(); $pool.Dispose()
$capped = $queue.Count -gt 0

# redirect chains: a 3xx whose target is itself a 3xx
$byUrl = @{}; foreach ($r in $rows) { $byUrl[$r.Address] = $r }
$chains = @()
foreach ($r in $rows | Where-Object { $_.Status -eq 'Redirect' }) {
  $hop = 1; $next = Normalize $r.'Redirect URL' $r.Address; $path = @($r.Address)
  while ($next -and $byUrl.ContainsKey($next) -and $byUrl[$next].Status -eq 'Redirect' -and $hop -lt 10) { $path += $next; $hop++; $next = Normalize $byUrl[$next].'Redirect URL' $next }
  if ($hop -ge 2) { $chains += [pscustomobject]@{ Source = $r.Address; Hops = $hop; Chain = ($path -join ' -> ') + " -> $next" } }
}

$OutDir = [IO.Path]::GetFullPath($OutDir); $sfDir = Join-Path $OutDir 'sf'; New-Item -ItemType Directory -Force $sfDir | Out-Null
$rows | Export-Csv (Join-Path $sfDir 'internal_all.csv') -NoTypeInformation -Encoding UTF8
$chains | Export-Csv (Join-Path $sfDir 'redirect_chains.csv') -NoTypeInformation -Encoding UTF8

$html = @($rows | Where-Object { $_.'Status Code' -eq 200 -and $_.'Content Type' -match 'html' })
$idx = @($html | Where-Object { $_.Indexability -eq 'Indexable' })
function DupCount($set, $prop) { @($set | Where-Object { $_.$prop } | Group-Object $prop | Where-Object Count -gt 1 | ForEach-Object { $_.Group }).Count }
$summary = [ordered]@{
  site = $Site; crawled_at = (Get-Date -Format s); minutes = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
  capped_at_max = $capped; max = $Max; method = 'crawl-site.ps1 (curl): homepage + sitemaps + internal links; HTML, redirects and errors only'
  'Crawled URLs' = $rows.Count
  '200 Status Code URLs' = @($rows | Where-Object { $_.'Status Code' -eq 200 }).Count
  'HTML Pages' = $html.Count
  '404s' = @($rows | Where-Object { $_.'Status Code' -eq 404 }).Count
  '300 Redirects' = @($rows | Where-Object { $_.Status -eq 'Redirect' }).Count
  '500 errors' = @($rows | Where-Object { $_.'Status Code' -ge 500 }).Count
  'Blocked by robots' = @($rows | Where-Object { $_.Status -eq 'Blocked by robots.txt' }).Count
  'Canonical Errors (Multiple and non-indexable canonicals)' = @($html | Where-Object { $_.'Canonical Link Element 1' -and $byUrl.ContainsKey($_.'Canonical Link Element 1') -and $byUrl[$_.'Canonical Link Element 1'].Indexability -ne 'Indexable' }).Count
  'Duplicate Titles' = DupCount $idx 'Title 1'
  'Duplicate Descriptions' = DupCount $idx 'Meta Description 1'
  'Duplicate H1s' = DupCount $idx 'H1-1'
  'Missing Titles' = @($idx | Where-Object { -not $_.'Title 1' }).Count
  'Missing Descriptions' = @($idx | Where-Object { -not $_.'Meta Description 1' }).Count
  'Missing H1s' = @($idx | Where-Object { $_.'H1 Count' -eq 0 }).Count
  'Multiple H1s' = @($idx | Where-Object { $_.'H1 Count' -gt 1 }).Count
  'Insecure Content' = @($html | Where-Object { $_.'Insecure Resources' -gt 0 }).Count
  'Redirect Chains' = $chains.Count
  'SF - HTML pages with response time over 2s' = @($html | Where-Object { [double]$_.'Response Time' -gt 2 }).Count
  'Non-indexable in sitemap' = @($rows | Where-Object { $_.'In Sitemap' -and $_.Indexability -ne 'Indexable' }).Count
  note = 'Response times are inflated under parallel load; confirm a slow site with PSI / DevTools before reporting it.'
}
Write-Utf8NoBom (Join-Path $sfDir 'crawl-summary.json') ($summary | ConvertTo-Json)
"Crawled $($rows.Count) URLs in $($summary.minutes) min$(if ($capped) { ' (CAPPED - raise -Max)' }); HTML $($html.Count), 404 $($summary.'404s'), 3xx $($summary.'300 Redirects'), missing H1 $($summary.'Missing H1s'), missing meta $($summary.'Missing Descriptions'), dup titles $($summary.'Duplicate Titles')"
