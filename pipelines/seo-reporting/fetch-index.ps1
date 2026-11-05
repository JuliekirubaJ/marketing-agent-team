<#
.SYNOPSIS
  Replaces the manual GSC "Indexing" inputs. Reads every URL in the site's XML sitemaps and asks
  Google's URL Inspection API (the owner's read-only sign-in) how each one stands. Writes:
    gsc\url-inspection.csv  - one row per sitemap URL (verdict, coverage, fetch, robots, indexing, rich results)
    gsc\index-summary.json  - the counts for the report's GSC rows
  Counts cover SUBMITTED (sitemap) URLs, which is what the GSC sitemap/indexing rows measure. Pages
  Google found elsewhere and never saw in a sitemap are not included.

  Sitemaps: the Sitemap: lines in robots.txt, else /sitemap_index.xml, else /sitemap.xml.
  Quota: 2,000 inspections per property per day (600 per minute); -Max caps a run.
  Each inspection takes about 7 s server-side, so the run is parallel (8 at a time): budget roughly
  1 minute per 70 URLs.

  -OutDir defaults to <root>\seo\_exports\<current YYYY-MM>\<site>.

.EXAMPLE
  .\fetch-index.ps1 -Site main
#>
param(
  [Parameter(Mandatory)][string]$Site,
  [string]$OutDir,
  [int]$Max = 1900,
  [string]$Root
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
. (Join-Path $PSScriptRoot 'google-auth.ps1') -Action Lib
$cfg = Get-SeoSite $Root $Site
if (-not $OutDir) { $OutDir = Join-Path (Get-SeoDataDir $Root) ("_exports\" + (Get-Date -Format 'yyyy-MM') + "\$Site") }

function Get-SitemapUrls([string]$u, [int]$depth = 0) {
  if ($depth -gt 3) { return }
  try { $x = [xml](Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 60).Content } catch { Write-Warning "sitemap fetch failed: $u"; return }
  if ($x.sitemapindex) { foreach ($s in $x.sitemapindex.sitemap) { Get-SitemapUrls $s.loc ($depth + 1) } }
  elseif ($x.urlset) { foreach ($l in $x.urlset.url) { [pscustomobject]@{ sitemap = ($u -split '/')[-1]; url = $l.loc.Trim() } } }
}

$robots = ''; try { $robots = (Invoke-WebRequest "$($cfg.Origin)/robots.txt" -UseBasicParsing -TimeoutSec 30).Content } catch {}
$urls = @()
foreach ($sm in (Get-SitemapCandidates $cfg.Origin $robots)) {
  $urls = @(Get-SitemapUrls $sm | Sort-Object url -Unique)
  if ($urls.Count) { break }
}
if (-not $urls.Count) { throw "No sitemap URLs found for $($cfg.Origin)" }
$submitted = $urls.Count
if ($urls.Count -gt $Max) { $urls = $urls[0..($Max - 1)] }
$OutDir = [IO.Path]::GetFullPath($OutDir); $gscDir = Join-Path $OutDir 'gsc'
New-Item -ItemType Directory -Force $gscDir | Out-Null

# A fresh token per chunk of 200 keeps long runs under the 60-minute token life.
$inspect = {
  param($url, $prop, $token)
  $body = @{ inspectionUrl = $url; siteUrl = $prop } | ConvertTo-Json
  $err = ''
  for ($try = 1; $try -le 4; $try++) {
    try { return @{ url = $url; r = (Invoke-RestMethod -Method Post -Uri 'https://searchconsole.googleapis.com/v1/urlInspection/index:inspect' -Headers @{ Authorization = "Bearer $token" } -ContentType 'application/json' -Body $body -TimeoutSec 90); err = '' } }
    catch {
      $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
      $err = "HTTP $code"
      if ($code -eq 429 -or $code -ge 500 -or $code -eq 0) { Start-Sleep -Seconds (10 * $try) } else { break }
    }
  }
  return @{ url = $url; r = $null; err = $err }
}
$results = @{}
[Net.ServicePointManager]::DefaultConnectionLimit = 32   # .NET default is 2 per host, which serialises the pool
$pool = [RunspaceFactory]::CreateRunspacePool(1, 8); $pool.Open()
try {
  for ($start = 0; $start -lt $urls.Count; $start += 200) {
    $token = Get-GoogleAccessToken
    $chunk = $urls[$start..([Math]::Min($start + 199, $urls.Count - 1))]
    $jobs = foreach ($u in $chunk) { $ps = [PowerShell]::Create(); $ps.RunspacePool = $pool; [void]$ps.AddScript($inspect).AddArgument($u.url).AddArgument($cfg.GscProperty).AddArgument($token); @{ ps = $ps; h = $ps.BeginInvoke() } }
    foreach ($j in $jobs) { $o = $j.ps.EndInvoke($j.h); $j.ps.Dispose(); foreach ($x in $o) { $results[$x.url] = $x } }
    Write-Host "  inspected $([Math]::Min($start + 200, $urls.Count)) / $($urls.Count)"
  }
} finally { $pool.Close(); $pool.Dispose() }

$rows = New-Object System.Collections.Generic.List[object]
foreach ($u in $urls) {
  $res = $results[$u.url]; $r = if ($res) { $res.r } else { $null }; $err = if ($res) { $res.err } else { 'not run' }
  $i = if ($r) { $r.inspectionResult.indexStatusResult } else { $null }
  $rr = if ($r) { $r.inspectionResult.richResultsResult } else { $null }
  $richErrors = 0
  if ($rr) { foreach ($d in @($rr.detectedItems)) { foreach ($it in @($d.items)) { foreach ($is in @($it.issues)) { if ($is.severity -eq 'ERROR') { $richErrors++ } } } } }
  $rows.Add([pscustomobject]@{
    url = $u.url; sitemap = $u.sitemap
    verdict = if ($i) { $i.verdict } else { 'ERROR' }; coverage = if ($i) { $i.coverageState } else { $err }
    page_fetch = $i.pageFetchState; robots = $i.robotsTxtState; indexing = $i.indexingState
    google_canonical = $i.googleCanonical; user_canonical = $i.userCanonical; last_crawl = $i.lastCrawlTime
    rich_verdict = if ($rr) { $rr.verdict } else { '' }; rich_error_items = $richErrors
  })
}
$rows | Export-Csv (Join-Path $gscDir 'url-inspection.csv') -NoTypeInformation -Encoding UTF8

$c = { param($f) @($rows | Where-Object $f).Count }
$summary = [ordered]@{
  site = $Site; checked = (Get-Date -Format s); sitemap_submitted = $submitted; inspected = $rows.Count
  sitemap_indexed = & $c { $_.verdict -eq 'PASS' }
  not_indexed = & $c { $_.verdict -ne 'PASS' -and $_.verdict -ne 'ERROR' }
  not_found_404 = & $c { $_.page_fetch -eq 'NOT_FOUND' }
  soft_404 = & $c { $_.page_fetch -eq 'SOFT_404' }
  server_error_5xx = & $c { $_.page_fetch -eq 'SERVER_ERROR' }
  blocked_by_robots = & $c { $_.robots -eq 'DISALLOWED' -or $_.page_fetch -eq 'BLOCKED_ROBOTS_TXT' }
  noindex = & $c { $_.indexing -match 'BLOCKED_BY_(META_TAG|HTTP_HEADER)' }
  redirect = & $c { $_.page_fetch -eq 'REDIRECT_ERROR' -or $_.coverage -match 'redirect' }
  canonical_mismatch = & $c { $_.google_canonical -and $_.user_canonical -and $_.google_canonical -ne $_.user_canonical }
  structured_data_error_pages = & $c { $_.rich_verdict -eq 'FAIL' }
  crawled_not_indexed = & $c { $_.coverage -match 'Crawled - currently not indexed' }
  discovered_not_indexed = & $c { $_.coverage -match 'Discovered - currently not indexed' }
  unknown_to_google = & $c { $_.coverage -match 'unknown to Google' }
  api_errors = & $c { $_.verdict -eq 'ERROR' }
  coverage_breakdown = [ordered]@{}
}
foreach ($g in ($rows | Group-Object coverage | Sort-Object Count -Descending)) { $summary.coverage_breakdown[$g.Name] = $g.Count }
Write-Utf8NoBom (Join-Path $gscDir 'index-summary.json') ($summary | ConvertTo-Json -Depth 4)
"Inspected $($rows.Count) of $submitted sitemap URLs: indexed $($summary.sitemap_indexed), not indexed $($summary.not_indexed), 404 $($summary.not_found_404), soft404 $($summary.soft_404), 5xx $($summary.server_error_5xx), robots-blocked $($summary.blocked_by_robots), noindex $($summary.noindex), rich-result errors $($summary.structured_data_error_pages), API errors $($summary.api_errors)"
