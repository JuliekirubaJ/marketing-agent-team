<#
.SYNOPSIS
  Checks every agent, skill and command for frontmatter that Claude Code would silently skip,
  scans for leftover brand names and absolute paths, and regenerates the agent list in
  .claude-plugin/plugin.json.

.EXAMPLE
  .\scripts\validate.ps1            # check only
  .\scripts\validate.ps1 -Fix       # also rewrite plugin.json agent list
  .\scripts\validate.ps1 -Banned 'acme','widgetco'   # extra words to flag
#>
param(
  [switch]$Fix,
  [string[]]$Banned = @()
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$errors = New-Object System.Collections.Generic.List[string]
$warns  = New-Object System.Collections.Generic.List[string]

function Get-Frontmatter([string]$path) {
  $lines = Get-Content -LiteralPath $path -Encoding UTF8
  if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $null }
  $fm = @()
  for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') { return ,$fm }
    $fm += $lines[$i]
  }
  return $null
}

function Test-YamlValue([string]$key, [string]$value, [string]$file) {
  $v = $value.Trim()
  if ($v -eq '') { return }
  $quoted = ($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))
  if ($quoted) {
    if ($v.StartsWith('"')) {
      $inner = $v.Substring(1, $v.Length - 2)
      if ($inner -match '(?<!\\)"') { $errors.Add("$file : '$key' has an unescaped double quote inside a double-quoted value") }
    }
    return
  }
  if ($v -match '^[\[\{"''>|*&!%@`]') { $errors.Add("$file : '$key' starts with a YAML special character - wrap it in quotes") }
  if ($v -match ': ')                  { $errors.Add("$file : '$key' contains ': ' - wrap the value in double quotes") }
  if ($v -match ' #')                  { $errors.Add("$file : '$key' contains ' #' (read as a comment) - wrap it in quotes") }
}

function Test-File([string]$file, [string]$expectedName, [bool]$needName) {
  $fm = Get-Frontmatter $file
  if ($null -eq $fm) { $errors.Add("$file : missing or unterminated frontmatter (line 1 must be ---)"); return }
  $keys = @{}
  foreach ($l in $fm) {
    if ($l -match '^([A-Za-z0-9_-]+):\s?(.*)$') {
      $keys[$matches[1]] = $matches[2]
      Test-YamlValue $matches[1] $matches[2] $file
    }
  }
  if (-not $keys.ContainsKey('description')) { $errors.Add("$file : missing description") }
  if ($needName) {
    if (-not $keys.ContainsKey('name')) { $errors.Add("$file : missing name") }
    elseif ($keys['name'].Trim('"', "'", ' ') -ne $expectedName) { $errors.Add("$file : name '$($keys['name'])' does not match '$expectedName'") }
  }
}

$agents = Get-ChildItem .claude/agents -Recurse -Filter *.md | Sort-Object FullName
foreach ($a in $agents) { Test-File $a.FullName $a.BaseName $true }

$skills = Get-ChildItem .claude/skills -Recurse -Filter SKILL.md
foreach ($s in $skills) {
  if ($s.Directory.Parent.Name -ne 'skills') { $errors.Add("$($s.FullName) : skills must be exactly one level deep (.claude/skills/<name>/SKILL.md)") }
  Test-File $s.FullName $s.Directory.Name $true
}

foreach ($c in Get-ChildItem .claude/commands -Filter *.md) { Test-File $c.FullName $c.BaseName $false }

# Duplicate agent names
$agents | Group-Object BaseName | Where-Object Count -gt 1 | ForEach-Object { $errors.Add("duplicate agent name: $($_.Name)") }

# Leftover absolute paths and extra banned words
$pattern = 'C:\\Users\\|OneDrive - '
if ($Banned.Count -gt 0) { $pattern += '|' + (($Banned | ForEach-Object { [regex]::Escape($_) }) -join '|') }
Get-ChildItem -Recurse -File -Include *.md,*.ps1,*.csv,*.json,*.js,*.html,*.css |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -ne 'conventions.md' -and $_.Name -ne 'validate.ps1' } |
  Select-String -Pattern $pattern | ForEach-Object { $warns.Add("$($_.Path):$($_.LineNumber) : $($_.Line.Trim())") }

# Plugin manifest agent list
$pj = '.claude-plugin/plugin.json'
$rel = $agents | ForEach-Object { './' + ($_.FullName.Substring($root.Length + 1) -replace '\\', '/') }
if ($Fix) {
  $json = Get-Content $pj -Raw | ConvertFrom-Json
  $json.agents = @($rel)
  ($json | ConvertTo-Json -Depth 5) | Set-Content -Path $pj -Encoding ASCII
  Write-Host "plugin.json agent list updated ($($rel.Count) agents)"
} else {
  $listed = (Get-Content $pj -Raw | ConvertFrom-Json).agents
  $missing = $rel | Where-Object { $listed -notcontains $_ }
  foreach ($m in $missing) { $errors.Add("plugin.json does not list $m (run with -Fix)") }
}

Write-Host ("Agents: {0}  Skills: {1}  Commands: {2}" -f $agents.Count, $skills.Count, (Get-ChildItem .claude/commands -Filter *.md).Count)
foreach ($w in $warns)  { Write-Host "WARN  $w" -ForegroundColor Yellow }
foreach ($e in $errors) { Write-Host "ERROR $e" -ForegroundColor Red }
if ($errors.Count -gt 0) { exit 1 } else { Write-Host 'OK - all frontmatter valid' -ForegroundColor Green }
