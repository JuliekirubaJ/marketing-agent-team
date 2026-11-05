<#
.SYNOPSIS
  Shared helpers for the SEO reporting scripts. Dot-source it:  . (Join-Path $PSScriptRoot 'seo-common.ps1')

  Root      : -Root, else $env:MARKETING_ROOT, else the repo root (two levels above this folder).
  Sites     : <root>\config\sites.csv (falls back to the repo's config\sites.csv).
              Columns: key,domain,ga4_property,gsc_property,clicky_site_id,notes
  Data      : <root>\seo\  (_exports\, rankings\, reports\)
  Secrets   : %USERPROFILE%\.marketing-agent-team\  (keys.json, google-client.json, google-token.json)
              Never stored in the repo, never printed.
  Editable lists (keywords, AEO prompts, AEO focus, content log): <root>\seo\rankings\<file>.csv
              when present, otherwise the starter copy in pipelines\seo-reporting\templates\.
#>

$script:SeoRepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))

function Resolve-SeoRoot([string]$Root) {
  if ($Root) { return [IO.Path]::GetFullPath($Root) }
  if ($env:MARKETING_ROOT) { return [IO.Path]::GetFullPath($env:MARKETING_ROOT) }
  return $script:SeoRepoRoot
}

function Get-SecretsDir {
  $d = Join-Path $env:USERPROFILE '.marketing-agent-team'
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force $d | Out-Null }
  return $d
}

function Get-SeoKeys {
  $p = Join-Path (Get-SecretsDir) 'keys.json'
  if (Test-Path $p) { return (Get-Content $p -Raw | ConvertFrom-Json) }
  return $null
}

function Get-SeoDataDir([string]$Root) { return (Join-Path (Resolve-SeoRoot $Root) 'seo') }

function Get-SeoListFile([string]$Root, [string]$Name) {
  # live copy under <root>\seo\rankings\ wins; the template is the starter list
  $live = Join-Path (Get-SeoDataDir $Root) "rankings\$Name"
  if (Test-Path $live) { return $live }
  return (Join-Path $PSScriptRoot "templates\$Name")
}

function Get-SeoSites([string]$Root) {
  $r = Resolve-SeoRoot $Root
  $f = Join-Path $r 'config\sites.csv'
  if (-not (Test-Path $f)) { $f = Join-Path $script:SeoRepoRoot 'config\sites.csv' }
  if (-not (Test-Path $f)) { throw "No config\sites.csv under $r or the repo root" }
  return @(Import-Csv $f | Where-Object { $_.key -and $_.domain })
}

function Get-SeoSite([string]$Root, [string]$Key) {
  $row = Get-SeoSites $Root | Where-Object { $_.key -eq $Key } | Select-Object -First 1
  if (-not $row) { throw "Site '$Key' is not in config\sites.csv (keys: $((Get-SeoSites $Root | ForEach-Object { $_.key }) -join ', '))" }
  $domain = ($row.domain.Trim() -replace '^https?://', '').TrimEnd('/')
  $origin = "https://$domain"
  $gsc = if ($row.gsc_property) { $row.gsc_property.Trim() } else { "$origin/" }
  # A domain property (sc-domain:) covers every subdomain. Page lists are filtered to this host only;
  # never page-filter device/query/country breakdowns, because GSC then drops rows.
  $bare = $domain -replace '^www\.', ''
  $pageRx = if ($gsc -like 'sc-domain:*') { '^https?://(www\.)?' + [regex]::Escape($bare) + '/' } else { $null }
  $ga4 = if ($row.ga4_property) { ($row.ga4_property.Trim() -replace '^properties/', '') } else { '' }
  return [pscustomobject]@{
    Key = $row.key; Domain = $domain; Origin = $origin; Home = "$origin/"
    GscProperty = $gsc; PageRegex = $pageRx; Ga4Property = $ga4
    ClickySiteId = "$($row.clicky_site_id)".Trim(); Notes = $row.notes
  }
}

function Get-SitemapCandidates([string]$Origin, [string]$RobotsBody) {
  $c = @()
  foreach ($line in ("$RobotsBody" -split "`n")) { if ($line -match '^(?i)\s*sitemap:\s*(\S+)') { $c += $Matches[1].Trim() } }
  $c += "$Origin/sitemap_index.xml"; $c += "$Origin/sitemap.xml"
  return @($c | Select-Object -Unique)
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
  $full = [IO.Path]::GetFullPath($Path)
  New-Item -ItemType Directory -Force (Split-Path $full) | Out-Null
  [IO.File]::WriteAllText($full, $Text, (New-Object Text.UTF8Encoding($false)))
}
