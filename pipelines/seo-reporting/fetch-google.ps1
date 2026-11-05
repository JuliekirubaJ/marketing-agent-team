<#
.SYNOPSIS
  Pulls Search Console + GA4 data for one site through the saved Google sign-in (google-auth.ps1)
  and writes the same files a manual export would have produced.

  Search Console (always):
    gsc\Devices.csv, gsc\Queries.csv (top 1000), gsc\Pages.csv (top 1000), gsc\Countries.csv,
    gsc\QueryPage.csv (query x page, for rankings / cannibalisation), gsc\Totals.csv,
    gsc\Sitemaps.csv (submitted per sitemap; the API no longer reports indexed counts reliably)
  GA4 (only when config\sites.csv has a ga4_property for the site):
    ga4-totals.csv, ga4-channels.csv, ga4-devices.csv (organic), ga4-countries.csv (organic),
    ga4-landing.csv (organic, top 100), ga4-ai-sources.csv and ga4-ai-landing.csv (AI Assistant channel)

  -OutDir defaults to <root>\seo\_exports\<YYYY-MM of -To>\<site>.

.EXAMPLE
  .\fetch-google.ps1 -Site main -From 2026-09-01 -To 2026-09-28
#>
param(
  [Parameter(Mandatory)][string]$Site,
  [Parameter(Mandatory)][string]$From,
  [Parameter(Mandatory)][string]$To,
  [string]$OutDir,
  [string]$Root
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'seo-common.ps1')
. (Join-Path $PSScriptRoot 'google-auth.ps1') -Action Lib
$cfg = Get-SeoSite $Root $Site
if (-not $OutDir) { $OutDir = Join-Path (Get-SeoDataDir $Root) ("_exports\" + $To.Substring(0, 7) + "\$Site") }

$OutDir = [IO.Path]::GetFullPath($OutDir)
$gscDir = Join-Path $OutDir 'gsc'
New-Item -ItemType Directory -Force $gscDir | Out-Null
$token = Get-GoogleAccessToken
$hdr = @{ Authorization = "Bearer $token" }
$log = @()

function Invoke-Gsc([string[]]$dims, [int]$limit = 1000) {
  $body = @{ startDate = $From; endDate = $To; dimensions = $dims; rowLimit = $limit; dataState = 'final' }
  # Page-filtering a domain property makes GSC drop rows once other dimensions are added (seen in practice:
  # device clicks summed to about 75% of the unfiltered total). Subdomains usually add almost nothing,
  # so filter only the page lists.
  if ($cfg.PageRegex -and ($dims -contains 'page')) {
    $body.dimensionFilterGroups = @(@{ filters = @(@{ dimension = 'page'; operator = 'includingRegex'; expression = $cfg.PageRegex }) })
  }
  $u = "https://www.googleapis.com/webmasters/v3/sites/$([uri]::EscapeDataString($cfg.GscProperty))/searchAnalytics/query"
  $r = Invoke-RestMethod -Method Post -Uri $u -Headers $hdr -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 8)
  foreach ($row in @($r.rows)) {
    if (-not $row) { continue }
    $o = [ordered]@{}
    for ($i = 0; $i -lt $dims.Count; $i++) { $o[(Get-Culture).TextInfo.ToTitleCase($dims[$i])] = $row.keys[$i] }
    $o.Clicks = $row.clicks; $o.Impressions = $row.impressions
    $o.CTR = [math]::Round($row.ctr, 4); $o.Position = [math]::Round($row.position, 2)
    [pscustomobject]$o
  }
}

# ---- Search Console ----
try {
  $tot = @(Invoke-Gsc @() 1)
  $tot | Export-Csv (Join-Path $gscDir 'Totals.csv') -NoTypeInformation -Encoding UTF8
  foreach ($spec in @(@('device','Devices',10), @('query','Queries',1000), @('page','Pages',1000), @('country','Countries',250))) {
    $rows = @(Invoke-Gsc @($spec[0]) $spec[2])
    $rows | Export-Csv (Join-Path $gscDir "$($spec[1]).csv") -NoTypeInformation -Encoding UTF8
    $log += "GSC $($spec[1]): $($rows.Count) rows"
  }
  $qp = @(Invoke-Gsc @('query','page') 5000)
  $qp | Export-Csv (Join-Path $gscDir 'QueryPage.csv') -NoTypeInformation -Encoding UTF8
  $log += "GSC QueryPage: $($qp.Count) rows"
  if ($tot) { $log += "GSC totals: clicks $($tot[0].Clicks), impressions $($tot[0].Impressions), CTR $($tot[0].CTR), position $($tot[0].Position)" }
} catch { $log += "GSC ERROR: $($_.Exception.Message)" }

try {
  $sm = Invoke-RestMethod -Uri "https://www.googleapis.com/webmasters/v3/sites/$([uri]::EscapeDataString($cfg.GscProperty))/sitemaps" -Headers $hdr
  $smRows = foreach ($s in @($sm.sitemap)) {
    if (-not $s) { continue }
    # contents[] has one entry per type (web, image, video); only 'web' is page URLs. Summing all of
    # them can inflate "submitted" several times over (image entries dominate on image-heavy sites).
    $sub = 0; $img = 0
    foreach ($c in @($s.contents)) { if ($c) { if ($c.type -eq 'web') { $sub += [int64]$c.submitted } elseif ($c.type -eq 'image') { $img += [int64]$c.submitted } } }
    [pscustomobject]@{ Sitemap = $s.path; Submitted = $sub; SubmittedImages = $img; LastSubmitted = $s.lastSubmitted; LastDownloaded = $s.lastDownloaded; Errors = $s.errors; Warnings = $s.warnings; IsIndex = $s.isSitemapsIndex }
  }
  @($smRows) | Export-Csv (Join-Path $gscDir 'Sitemaps.csv') -NoTypeInformation -Encoding UTF8
  $log += "GSC sitemaps: $(@($smRows).Count) listed"
} catch { $log += "GSC sitemaps ERROR: $($_.Exception.Message)" }

# ---- GA4 ----
$prop = $cfg.Ga4Property
if ($prop) {
  $organic = @{ filter = @{ fieldName = 'sessionDefaultChannelGroup'; stringFilter = @{ value = 'Organic Search' } } }
  function Invoke-Ga4([string]$file, [string[]]$dims, [string[]]$mets, $filter, [int]$limit = 250) {
    $body = @{ dateRanges = @(@{ startDate = $From; endDate = $To }); metrics = @($mets | ForEach-Object { @{ name = $_ } }); limit = $limit }
    if ($dims) { $body.dimensions = @($dims | ForEach-Object { @{ name = $_ } }) }
    if ($filter) { $body.dimensionFilter = $filter }
    if ($mets -contains 'sessions') { $body.orderBys = @(@{ metric = @{ metricName = 'sessions' }; desc = $true }) }
    $r = Invoke-RestMethod -Method Post -Uri "https://analyticsdata.googleapis.com/v1beta/properties/${prop}:runReport" -Headers $hdr -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 10)
    # a report with no dimensions has no dimensionHeaders; @($null) would count as 1 header
    $dh = @($r.dimensionHeaders | Where-Object { $_ } | ForEach-Object { $_.name }); $mh = @($r.metricHeaders | Where-Object { $_ } | ForEach-Object { $_.name })
    $rows = foreach ($row in @($r.rows)) {
      if (-not $row) { continue }
      $o = [ordered]@{}
      for ($i = 0; $i -lt $dh.Count; $i++) { $o[$dh[$i]] = $row.dimensionValues[$i].value }
      for ($i = 0; $i -lt $mh.Count; $i++) { $o[$mh[$i]] = $row.metricValues[$i].value }
      [pscustomobject]$o
    }
    @($rows) | Export-Csv (Join-Path $OutDir $file) -NoTypeInformation -Encoding UTF8
    return "GA4 ${file}: $(@($rows).Count) rows"
  }
  try {
    $log += Invoke-Ga4 'ga4-totals.csv' @() @('sessions','totalUsers','newUsers','engagedSessions','bounceRate','averageSessionDuration') $null 1
    $log += Invoke-Ga4 'ga4-channels.csv' @('sessionDefaultChannelGroup') @('sessions','totalUsers','newUsers','engagedSessions','bounceRate','averageSessionDuration') $null 50
    $log += Invoke-Ga4 'ga4-devices.csv' @('deviceCategory') @('totalUsers','newUsers','sessions') $organic 10
    $log += Invoke-Ga4 'ga4-countries.csv' @('country') @('totalUsers','newUsers','sessions','engagedSessions','engagementRate') $organic 250
    $log += Invoke-Ga4 'ga4-landing.csv' @('landingPagePlusQueryString') @('sessions','totalUsers','engagedSessions','engagementRate') $organic 100
    # AEO / GEO: which AI assistants send visitors, and where they land
    $ai = @{ filter = @{ fieldName = 'sessionDefaultChannelGroup'; stringFilter = @{ value = 'AI Assistant' } } }
    $log += Invoke-Ga4 'ga4-ai-sources.csv' @('sessionSource') @('sessions','totalUsers','engagedSessions','engagementRate') $ai 50
    $log += Invoke-Ga4 'ga4-ai-landing.csv' @('landingPagePlusQueryString') @('sessions','totalUsers','engagedSessions','engagementRate') $ai 50
  } catch { $log += "GA4 ERROR: $($_.Exception.Message) (is the Google Analytics Data API enabled in the OAuth client's project?)" }
} else { $log += "GA4 skipped: no ga4_property for '$Site' in config\sites.csv" }

$log | ForEach-Object { $_ }
