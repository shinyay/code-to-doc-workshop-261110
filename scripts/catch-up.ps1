# Windows version of scripts/catch-up.sh. Same arguments and exit codes.
# Usage: pwsh scripts/catch-up.ps1 <point> [--dry-run]
#   exit 0: done / 1: could not apply or uncommitted changes / 3: bad usage or no patch
$ErrorActionPreference = 'Stop'
function Fail([int]$code, [string]$message) { [Console]::Error.WriteLine($message); exit $code }
function Invoke-Git { git @args; if ($LASTEXITCODE -ne 0) { throw "git $args failed ($LASTEXITCODE)" } }
$Point = if ($args.Count -ge 1) { [string]$args[0] } else { '' }
$Mode = if ($args.Count -ge 2) { [string]$args[1] } else { '' }
if ($Point -notmatch '^[A-Za-z0-9][A-Za-z0-9-]*$' -or ($Mode -ne '' -and $Mode -ne '--dry-run')) {
  Fail 3 'usage: pwsh scripts/catch-up.ps1 <point> [--dry-run]'
}
Set-Location (git rev-parse --show-toplevel)
$patch = "catch-up/$Point.patch"
if (-not (Test-Path $patch)) { Fail 3 "no patch for point ${Point}: $patch" }
Invoke-Git fetch --quiet origin main
$base = (git rev-list --max-parents=0 origin/main | Select-Object -Last 1)
if ($Mode -eq '--dry-run') {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("catch-up-" + [guid]::NewGuid())
  try {
    Invoke-Git worktree add --quiet --detach $tmp $base
    git -C $tmp apply --check (Resolve-Path $patch).Path
    $ok = ($LASTEXITCODE -eq 0)
  } finally { git worktree remove --force $tmp 2>$null | Out-Null }
  if ($ok) { "dry-run ok: $patch applies to $base"; exit 0 }
  Fail 1 "dry-run failed: $patch does not apply to $base"
}
git diff --quiet; $a = $LASTEXITCODE; git diff --cached --quiet; $b = $LASTEXITCODE
if ($a -ne 0 -or $b -ne 0) { Fail 1 'uncommitted changes found. commit or stash them first (git stash -u).' }
# The patch lives on main; keep a copy before switching to the base commit.
$saved = [IO.Path]::GetTempFileName()
Copy-Item $patch $saved -Force
try {
  Invoke-Git switch -c "catch-up/$Point" $base
  Invoke-Git apply --index $saved
} finally { Remove-Item $saved -ErrorAction SilentlyContinue }
Invoke-Git commit --quiet -m "catch up to recovery point $Point"
"now on branch catch-up/$Point. push with: git push -u origin catch-up/$Point"
