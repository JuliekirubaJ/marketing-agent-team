<#
.SYNOPSIS
  Google sign-in for the SEO reports (Search Console + GA4, read-only scopes), under the owner's own account.

  -Action Login : opens Google's consent page in the default browser and also prints the link (on some
                  machines Start-Process shows no browser). The owner signs in. A loopback listener on
                  127.0.0.1 receives the code (PKCE), exchanges it, and saves the refresh token to
                  %USERPROFILE%\.marketing-agent-team\google-token.json. No secret is printed.
  -Action Test  : refreshes an access token and lists the Search Console sites and GA4 properties
                  this login can see.
  -Action Lib   : (default) defines the functions only. Other scripts dot-source this file and call
                  Get-GoogleAccessToken.

  Client file: %USERPROFILE%\.marketing-agent-team\google-client.json (a Desktop-type OAuth client,
  downloaded from Google Cloud Console > APIs & Services > Credentials).

  If a refresh fails with invalid_grant the sign-in has expired. That happens after 7 days while the
  OAuth consent screen is "External + Testing". Publish the app (or use an Internal consent screen) and
  run -Action Login again. Never guess data while signed out.
#>
param([ValidateSet('Login','Test','Lib')][string]$Action = 'Lib')

$script:GKeyDir = Join-Path $env:USERPROFILE '.marketing-agent-team'
if (-not (Test-Path $script:GKeyDir)) { New-Item -ItemType Directory -Force $script:GKeyDir | Out-Null }
$script:ClientFile = Join-Path $script:GKeyDir 'google-client.json'
$script:TokenFile  = Join-Path $script:GKeyDir 'google-token.json'
$script:Scopes     = 'https://www.googleapis.com/auth/webmasters.readonly https://www.googleapis.com/auth/analytics.readonly'

function Get-GoogleClient {
  if (-not (Test-Path $script:ClientFile)) { throw "Missing $script:ClientFile (download a Desktop OAuth client JSON and save it there)" }
  $j = Get-Content $script:ClientFile -Raw | ConvertFrom-Json
  if ($j.installed) { return $j.installed } else { throw 'google-client.json is not a Desktop (installed) OAuth client' }
}

function ConvertTo-B64Url([byte[]]$b) { [Convert]::ToBase64String($b).TrimEnd('=').Replace('+','-').Replace('/','_') }

function Invoke-GoogleLogin {
  $c = Get-GoogleClient
  $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
  $vb = New-Object byte[] 48; $rng.GetBytes($vb); $verifier = ConvertTo-B64Url $vb
  $challenge = ConvertTo-B64Url ([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::ASCII.GetBytes($verifier)))
  $sb = New-Object byte[] 16; $rng.GetBytes($sb); $state = ConvertTo-B64Url $sb

  $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0)
  $listener.Start()
  $port = $listener.LocalEndpoint.Port
  $redirect = "http://127.0.0.1:$port"
  $url = 'https://accounts.google.com/o/oauth2/v2/auth?' + (@(
    "client_id=$([uri]::EscapeDataString($c.client_id))",
    "redirect_uri=$([uri]::EscapeDataString($redirect))",
    'response_type=code',
    "scope=$([uri]::EscapeDataString($script:Scopes))",
    "code_challenge=$challenge", 'code_challenge_method=S256',
    "state=$state", 'access_type=offline', 'prompt=consent'
  ) -join '&')
  # the URL holds only the public client id and one-time PKCE values, no secrets
  [IO.File]::WriteAllText((Join-Path $script:GKeyDir 'login-url.txt'), $url)
  try { Start-Process $url } catch {}
  "If no browser tab opened, open this link yourself:"
  $url
  "Sign in with the Google account that can read Search Console and GA4, then click Allow (waiting up to 30 minutes)..."

  $deadline = (Get-Date).AddMinutes(30); $code = $null; $err = $null
  try {
    while (-not $code -and -not $err -and (Get-Date) -lt $deadline) {
      if (-not $listener.Pending()) { Start-Sleep -Milliseconds 300; continue }
      $client = $listener.AcceptTcpClient()
      $stream = $client.GetStream(); $reader = New-Object IO.StreamReader($stream)
      $line = $reader.ReadLine()
      $q = @{}
      if ($line -match '^GET\s+/\?([^\s]+)') {
        foreach ($kv in $Matches[1] -split '&') { $p = $kv -split '=', 2; if ($p.Count -eq 2) { $q[$p[0]] = [uri]::UnescapeDataString($p[1]) } }
      }
      if ($q['state'] -and $q['state'] -ne $state) { $err = 'state mismatch' }
      elseif ($q['error']) { $err = $q['error'] }
      elseif ($q['code']) { $code = $q['code'] }
      $msg = if ($code) { 'Signed in. You can close this tab.' } elseif ($err) { "Sign-in failed: $err" } else { '' }
      $html = "<html><body style='font-family:Segoe UI;padding:40px'><h2>$msg</h2></body></html>"
      $bytes = [Text.Encoding]::UTF8.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $([Text.Encoding]::UTF8.GetByteCount($html))`r`nConnection: close`r`n`r`n$html")
      $stream.Write($bytes, 0, $bytes.Length); $stream.Flush(); $client.Close()
    }
  } finally { $listener.Stop() }
  if ($err) { throw "Google sign-in failed: $err (access_denied usually means the account is not a test user on an External + Testing consent screen)" }
  if (-not $code) { throw 'Timed out waiting for Google sign-in.' }

  $tok = Invoke-RestMethod -Method Post -Uri 'https://oauth2.googleapis.com/token' -ContentType 'application/x-www-form-urlencoded' -Body @{
    client_id = $c.client_id; client_secret = $c.client_secret; code = $code; code_verifier = $verifier
    redirect_uri = $redirect; grant_type = 'authorization_code'
  }
  if (-not $tok.refresh_token) { throw 'Google returned no refresh token.' }
  $save = [ordered]@{ refresh_token = $tok.refresh_token; scope = $tok.scope; created = (Get-Date -Format s) }
  [IO.File]::WriteAllText($script:TokenFile, ($save | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
  "Saved sign-in to $script:TokenFile (scopes: $($tok.scope))"
}

function Get-GoogleAccessToken {
  if (-not (Test-Path $script:TokenFile)) { throw 'Not signed in - run google-auth.ps1 -Action Login' }
  $c = Get-GoogleClient
  $t = Get-Content $script:TokenFile -Raw | ConvertFrom-Json
  $r = Invoke-RestMethod -Method Post -Uri 'https://oauth2.googleapis.com/token' -ContentType 'application/x-www-form-urlencoded' -Body @{
    client_id = $c.client_id; client_secret = $c.client_secret; refresh_token = $t.refresh_token; grant_type = 'refresh_token'
  }
  return $r.access_token
}

function Invoke-GoogleApi([string]$Method, [string]$Uri, $Body) {
  $h = @{ Authorization = "Bearer $(Get-GoogleAccessToken)" }
  if ($null -ne $Body) { Invoke-RestMethod -Method $Method -Uri $Uri -Headers $h -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Depth 10) }
  else { Invoke-RestMethod -Method $Method -Uri $Uri -Headers $h }
}

if ($Action -eq 'Login') { Invoke-GoogleLogin }
elseif ($Action -eq 'Test') {
  "Search Console sites:"
  try { (Invoke-GoogleApi GET 'https://www.googleapis.com/webmasters/v3/sites').siteEntry | ForEach-Object { "  $($_.siteUrl)  [$($_.permissionLevel)]" } }
  catch { "  ERROR: $($_.Exception.Message)" }
  "GA4 properties:"
  try {
    $a = Invoke-GoogleApi GET 'https://analyticsadmin.googleapis.com/v1beta/accountSummaries?pageSize=200'
    foreach ($acc in $a.accountSummaries) { foreach ($p in $acc.propertySummaries) { "  $($p.property)  $($p.displayName)  (account: $($acc.displayName))" } }
  } catch { "  ERROR: $($_.Exception.Message)  (listing needs the 'Google Analytics Admin API' enabled; the Data API alone can't list properties. You can still copy the numeric property ID from GA4 > Admin > Property details into config\sites.csv)" }
}
