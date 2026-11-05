<#
.SYNOPSIS
  Weekly AEO technical health for one site: llms.txt, AI-crawler rules in robots.txt, robots.txt
  warnings, and answer-readiness of the tracked target pages (JSON-LD types, H1 count, meta
  description, question-style H2s). Reads raw server HTML (WordPress/Yoast and most CMSs render
  JSON-LD server-side), never a markdown conversion. Writes aeo-health.json.

  Target pages: the site's target_url values in keywords.csv (<root>\seo\rankings\ or templates\).
  -OutFile defaults to <root>\seo\_exports\weekly\<this Monday>\<site>\aeo-health.json.

.EXAMPLE
  .\aeo-checks.ps1 -Site main -OutFile C:\data\seo\_exports\weekly\2026-10-05\main\aeo-health.json
#>
param(
  [Parameter(Mandatory)][string]$Site,
  [string]$OutFile,
  [int]$MaxPages = 20,
  [string]$Root,
  [string]$KeywordsFile
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
$cfg = Get-SeoSite $Root $Site
if (-not $KeywordsFile) { $KeywordsFile = Get-SeoListFile $Root 'keywords.csv' }
if (-not $OutFile) {
  $d = (Get-Date).Date; $mon = $d.AddDays(-(([int]$d.DayOfWeek + 6) % 7))
  $OutFile = Join-Path (Get-SeoDataDir $Root) ("_exports\weekly\" + $mon.ToString('yyyy-MM-dd') + "\$Site\aeo-health.json")
}
$origin = $cfg.Origin
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36 SEOAuditCrawler'
function Get-Url([string]$u) {
  try { $r = Invoke-WebRequest $u -UseBasicParsing -UserAgent $ua -TimeoutSec 40 -MaximumRedirection 5; return @{ status = [int]$r.StatusCode; body = $r.Content } }
  catch {
    $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
    # some hosts drop the connection on 404s in a way .NET can't read; curl.exe reports the real code
    if ($code -eq 0) { try { $code = [int](& curl.exe -s -o NUL -A $ua --max-time 30 -w '%{http_code}' $u) } catch {} }
    return @{ status = $code; body = '' }
  }
}
$out = [ordered]@{ site = $Site; checked = (Get-Date -Format s); llms = $null; robots = $null; pages = @() }

# llms.txt
$l = Get-Url "$origin/llms.txt"
$looksMd = $l.body -match '(?m)^#\s'
# mojibake = UTF-8 read as Windows-1252 (A-tilde, or a-circumflex + euro sign). Built from char codes to keep this file ASCII.
$mojiRx = [string][char]0x00C3 + '|' + [char]0x00E2 + [char]0x20AC
$out.llms = [ordered]@{ status = $l.status; bytes = $l.body.Length; looks_like_markdown = $looksMd
  mojibake = [bool]($l.body -match $mojiRx); duplicate_h1 = (([regex]::Matches($l.body, '(?m)^#\s')).Count -gt 1) }

# robots.txt: AI crawler rules
$rb = Get-Url "$origin/robots.txt"
$bots = 'GPTBot','OAI-SearchBot','ChatGPT-User','ClaudeBot','Claude-SearchBot','PerplexityBot','Google-Extended','Applebot-Extended','CCBot','Bingbot'
$groups = @(); $cur = $null
foreach ($line in ($rb.body -split "`n")) {
  $t = ($line -replace '#.*$', '').Trim(); if (-not $t) { continue }
  if ($t -match '^(?i)user-agent:\s*(.+)$') { if (-not $cur -or $cur.rules.Count) { $cur = @{ agents = @(); rules = @() }; $groups += $cur }; $cur.agents += $Matches[1].Trim() }
  elseif ($cur -and $t -match '^(?i)(allow|disallow):\s*(.*)$') { $cur.rules += "$($Matches[1].ToLower()):$($Matches[2].Trim())" }
}
$botStatus = [ordered]@{}
foreach ($b in $bots) {
  $g = $groups | Where-Object { $_.agents -contains $b } | Select-Object -First 1
  $src = 'explicit'; if (-not $g) { $g = $groups | Where-Object { $_.agents -contains '*' } | Select-Object -First 1; $src = 'wildcard' }
  $blocked = $g -and ($g.rules -contains 'disallow:/')
  $botStatus[$b] = if ($blocked) { "BLOCKED ($src)" } else { "allowed ($src)" }
}
# robots.txt warnings (our own parser; GSC's robots.txt report has no API)
$warn = @(); $seenUA = $false
foreach ($line in ($rb.body -split "`n")) {
  $t2 = ($line -replace '#.*$', '').Trim(); if (-not $t2) { continue }
  if ($t2 -match '^(?i)user-agent:') { $seenUA = $true; continue }
  if ($t2 -match '^(?i)(allow|disallow|crawl-delay):' -and -not $seenUA) { $warn += "rule before any User-agent: $t2" }
  elseif ($t2 -match '^(?i)crawl-delay:') { $warn += "Crawl-delay is ignored by Google: $t2" }
  elseif ($t2 -notmatch '^(?i)(allow|disallow|sitemap|host|clean-param|request-rate|visit-time|content-signal):') { $warn += "unknown directive: $t2" }
}
$out.robots = [ordered]@{ status = $rb.status; crawl_delay_present = [bool]($rb.body -match '(?im)^\s*crawl-delay'); warnings_count = $warn.Count; warnings = $warn; ai_bots = $botStatus }

# target pages from the keyword list
$targets = @()
if (Test-Path $KeywordsFile) { $targets = @(Import-Csv $KeywordsFile | Where-Object { $_.site -eq $Site -and $_.target_url } | Select-Object -ExpandProperty target_url -Unique | Select-Object -First $MaxPages) }
if ($targets -notcontains "$origin/") { $targets = @("$origin/") + $targets }
foreach ($u in $targets) {
  $p = Get-Url $u; $h = $p.body
  $types = @([regex]::Matches($h, '"@type"\s*:\s*"([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
  $h2 = @([regex]::Matches($h, '(?is)<h2[^>]*>(.*?)</h2>') | ForEach-Object { ($_.Groups[1].Value -replace '<[^>]+>', '').Trim() })
  $meta = [regex]::Match($h, '(?is)<meta\s+name=["'']description["'']\s+content=["'']([^"'']*)')
  $out.pages += [ordered]@{
    url = $u; status = $p.status
    h1_count = ([regex]::Matches($h, '(?i)<h1[\s>]')).Count
    meta_description_chars = if ($meta.Success) { $meta.Groups[1].Value.Length } else { 0 }
    schema_types = ($types -join ', ')
    has_faq_schema = $types -contains 'FAQPage'; has_howto_schema = $types -contains 'HowTo'
    has_software_schema = [bool]($types | Where-Object { $_ -match 'SoftwareApplication|Product' })
    h2_count = $h2.Count; question_h2s = @($h2 | Where-Object { $_ -match '\?$|^(what|how|why|when|which|is|can|does|should)\b' }).Count
  }
}
Write-Utf8NoBom $OutFile ($out | ConvertTo-Json -Depth 6)
"Wrote $OutFile : llms.txt $($out.llms.status), robots $($out.robots.status), $($out.pages.Count) pages checked"
