<#
.SYNOPSIS
  Pulls the automatic SEO metrics for one site into a JSON file. Keys are read from
  %USERPROFILE%\.marketing-agent-team\keys.json (outside the repo and any synced folder) and are
  never printed.

  PSI:    PageSpeed Insights performance score, LCP and byte weight, desktop + mobile, homepage
          (needs psi_api_key)
  CrUX:   Core Web Vitals field data (p75 LCP / INP / CLS) for the origin and the tracked target pages
          (same psi_api_key; needs the Chrome UX Report API enabled in that key's Cloud project)
  Clicky: returning/new visitors, organic social, search + direct, avg time, bounce rate, AI referrals
          (needs clicky_site_id in config\sites.csv and clicky.<site>.sitekey in keys.json)
  Ahrefs: Domain Rating from the free public endpoint (needs ahrefs_api_key; optional)

  -OutFile defaults to <root>\seo\_exports\<YYYY-MM of -To>\<site>\auto-metrics.json.

.EXAMPLE
  .\fetch-auto.ps1 -Site main -From 2026-09-01 -To 2026-09-28
#>
param(
  [Parameter(Mandatory)][string]$Site,
  [Parameter(Mandatory)][string]$From,
  [Parameter(Mandatory)][string]$To,
  [string]$OutFile,
  [string]$Root,
  [string]$KeywordsFile
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
$cfg = Get-SeoSite $Root $Site
if (-not $OutFile) { $OutFile = Join-Path (Get-SeoDataDir $Root) ("_exports\" + $To.Substring(0, 7) + "\$Site\auto-metrics.json") }
if (-not $KeywordsFile) { $KeywordsFile = Get-SeoListFile $Root 'keywords.csv' }
$home_ = $cfg.Home
$keys = Get-SeoKeys
$out = [ordered]@{ site = $Site; url = $home_; window = "$From to $To"; fetched = (Get-Date -Format s); metrics = [ordered]@{}; errors = @() }

# --- PageSpeed Insights ---
# Scores swing between runs (a 30+ point mobile swing on the same day has been seen); treat one run as noisy.
if ($keys -and $keys.psi_api_key) {
  foreach ($strategy in 'desktop','mobile') {
    try {
      $u = "https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=$([uri]::EscapeDataString($home_))&strategy=$strategy&category=performance&key=$($keys.psi_api_key)"
      $p = Invoke-RestMethod $u -TimeoutSec 150
      $label = if ($strategy -eq 'desktop') { 'PageSpeed Insights Score (Desktop)' } else { 'PageSpeed Insights Score (Mobile)' }
      $out.metrics[$label] = [math]::Round($p.lighthouseResult.categories.performance.score * 100)
      $out.metrics["PSI $strategy LCP (s)"] = [math]::Round($p.lighthouseResult.audits.'largest-contentful-paint'.numericValue / 1000, 2)
      $out.metrics["PSI $strategy total byte weight (MB)"] = [math]::Round($p.lighthouseResult.audits.'total-byte-weight'.numericValue / 1MB, 2)
    } catch { $out.errors += "PSI ${strategy}: request failed (HTTP $(try { [int]$_.Exception.Response.StatusCode } catch { 0 }))" }
  }
} else { $out.errors += 'PSI: no psi_api_key in keys.json' }

# --- Clicky ---
$ckKey = if ($keys -and $keys.clicky) { $keys.clicky.$Site } else { $null }
$ckId = if ($cfg.ClickySiteId) { $cfg.ClickySiteId } elseif ($ckKey -and $ckKey.site_id) { $ckKey.site_id } else { '' }
if ($ckId -and $ckKey -and $ckKey.sitekey) {
  try {
    $types = 'visitors,visitors-new,bounce-rate,time-average,traffic-sources'
    $u = "https://api.clicky.com/api/stats/4?site_id=$ckId&sitekey=$($ckKey.sitekey)&type=$types&date=$From,$To&limit=all&output=json"
    $r = Invoke-RestMethod $u -TimeoutSec 60
    $get = { param($t) $x = $r | Where-Object { $_.type -eq $t }; if ($x -and $x.dates[0].items) { $x.dates[0].items } else { @() } }
    $visitors = [double]((& $get 'visitors')[0].value)
    $new = [double]((& $get 'visitors-new')[0].value)
    $out.metrics['Clicky New visitors'] = $new
    $out.metrics['Clicky Returning visitors'] = $visitors - $new
    $out.metrics['Clicky Bounce Rate (month avg)'] = [double]((& $get 'bounce-rate')[0].value) / 100
    $secs = [double]((& $get 'time-average')[0].value)
    $out.metrics['Clicky Average time per visit'] = '{0:mm\:ss}' -f [timespan]::FromSeconds($secs)
    $src = @{}; foreach ($i in (& $get 'traffic-sources')) { $src[$i.title] = [double]$i.value }
    $out.metrics['Clicky Organic social'] = if ($src.ContainsKey('Social media')) { $src['Social media'] } else { 0 }
    $out.metrics['Clicky Traffic source (Search + Direct)'] = ($(if ($src['Searches']) { $src['Searches'] } else { 0 }) + $(if ($src['Direct']) { $src['Direct'] } else { 0 }))
    # Clicky has its own "AI" traffic source (ChatGPT / Perplexity / Gemini visitors): the GEO metric
    $out.metrics['Clicky AI referrals'] = if ($src.ContainsKey('AI')) { $src['AI'] } else { 0 }
    $out.metrics['Clicky searches'] = if ($src.ContainsKey('Searches')) { $src['Searches'] } else { 0 }
    $out.metrics['Clicky traffic sources (all)'] = $src
  } catch { $out.errors += 'Clicky: request failed' }
} else { $out.errors += "Clicky: no site id / sitekey configured for $Site (rows are N/A for a site with no Clicky account)" }

# --- Core Web Vitals from the Chrome UX Report API (real-user field data, 28-day rolling) ---
# Replaces the manual GSC CWV rows. Pages: homepage + tracked target URLs; pages without enough
# Chrome traffic return 404 and are skipped.
if ($keys -and $keys.psi_api_key) {
  $pages = @($home_)
  if (Test-Path $KeywordsFile) { $pages += @(Import-Csv $KeywordsFile | Where-Object { $_.site -eq $Site -and $_.target_url } | Select-Object -ExpandProperty target_url -Unique) }
  $pages = @($pages | Select-Object -Unique | Select-Object -First 30)
  foreach ($ff in @(@('PHONE','mobile'), @('DESKTOP','desktop'))) {
    $checked = 0; $failing = @(); $originDone = $false
    foreach ($target in @('origin') + $pages) {
      $body = if ($target -eq 'origin') { @{ origin = $home_.TrimEnd('/'); formFactor = $ff[0] } } else { @{ url = $target; formFactor = $ff[0] } }
      try {
        $c = Invoke-RestMethod -Method Post -Uri "https://chromeuxreport.googleapis.com/v1/records:queryRecord?key=$($keys.psi_api_key)" -ContentType 'application/json' -Body ($body | ConvertTo-Json) -TimeoutSec 30
        $m = $c.record.metrics
        $lcp = [double]$m.largest_contentful_paint.percentiles.p75; $inp = [double]$m.interaction_to_next_paint.percentiles.p75; $cls = [double]$m.cumulative_layout_shift.percentiles.p75
        $good = ($lcp -le 2500) -and (-not $inp -or $inp -le 200) -and ($cls -le 0.1)
        if ($target -eq 'origin') {
          $out.metrics["CrUX $($ff[1]) origin LCP p75 (s)"] = [math]::Round($lcp / 1000, 2)
          $out.metrics["CrUX $($ff[1]) origin INP p75 (ms)"] = $inp
          $out.metrics["CrUX $($ff[1]) origin CLS p75"] = $cls
          $out.metrics["CrUX $($ff[1]) origin passes CWV"] = $good; $originDone = $true
        } else { $checked++; if (-not $good) { $failing += $target } }
      } catch {
        $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        if ($code -eq 403) { $out.errors += 'CrUX: Chrome UX Report API not enabled in the PSI key project'; break }
        # 404 = not enough Chrome traffic for this URL/origin; skip
      }
    }
    if ($checked -gt 0 -or $originDone) {
      $out.metrics["CWV $($ff[1]) issues"] = $failing.Count
      $out.metrics["CWV $($ff[1]) pages with field data"] = $checked
      $out.metrics["CWV $($ff[1]) failing pages"] = ($failing -join ' ')
    }
    if ($out.errors -match 'CrUX: Chrome UX') { break }
  }
}

# --- Ahrefs Domain Rating (free public endpoint; a free-plan key gets 401 on everything else) ---
# The endpoint needs POST with a JSON body; GET returns 400.
if ($keys -and $keys.ahrefs_api_key) {
  try {
    $r = Invoke-RestMethod -Method Post -Uri 'https://api.ahrefs.com/v3/public/domain-rating-free' -Headers @{ Authorization = "Bearer $($keys.ahrefs_api_key)"; Accept = 'application/json' } `
         -ContentType 'application/json' -Body (@{ targets = @($home_) } | ConvertTo-Json) -TimeoutSec 60
    $out.metrics['Ahrefs Domain Rating'] = [double]$r.domain_rating.targets[0].domain_rating
  } catch { $out.errors += 'Ahrefs DR: request failed' }
} else { $out.errors += 'Ahrefs DR: no ahrefs_api_key in keys.json (optional)' }

Write-Utf8NoBom $OutFile ($out | ConvertTo-Json -Depth 5)
"Wrote $OutFile  ($($out.metrics.Count) metrics, $($out.errors.Count) errors)"
$out.errors | ForEach-Object { "  ! $_" }
