# ORI Crash Course preflight check (Windows / PowerShell).
#
# Run this before the workshop. You want every line below to end in a
# green check. If a line is red, read the message under it, then check
# docs/troubleshooting.md before asking for help.
#
# Usage: .\scripts\preflight.ps1 [opencode|claude]
# Defaults to opencode. You can also set $env:ORI_AGENT = "claude"
# instead of passing an argument.

param(
    [string]$Agent = ""
)

$ErrorActionPreference = "Stop"

$ExpectedSkills = 25
$ColdStartSeconds = 20
if ([string]::IsNullOrEmpty($Agent)) {
    $Agent = if ($env:ORI_AGENT) { $env:ORI_AGENT } else { "opencode" }
}
$SandboxName = "ori-preflight-$PID"
$Failed = $false

function Write-Pass($msg) { Write-Host "✅ $msg" }
function Write-Fail($msg, $detail) {
    Write-Host "❌ $msg"
    Write-Host "   $detail"
    $script:Failed = $true
}
function Write-Note($msg, $detail) {
    Write-Host "⚠️  $msg"
    Write-Host "   $detail"
}

function Cleanup {
    try { sbx rm --force $SandboxName 2>$null | Out-Null } catch {}
}

try {
    if ($Agent -ne "opencode" -and $Agent -ne "claude") {
        Write-Host "Unknown agent '$Agent'. Use 'opencode' or 'claude', e.g.:"
        Write-Host "  .\scripts\preflight.ps1 claude"
        exit 1
    }

    Write-Host "Checking your setup for the $Agent lane..."
    Write-Host ""

    # 1. sbx on PATH and logged in
    $sbxOnPath = Get-Command sbx -ErrorAction SilentlyContinue
    $sbxLoggedIn = $false
    if ($sbxOnPath) {
        try { sbx ls 2>$null | Out-Null; $sbxLoggedIn = $true } catch { $sbxLoggedIn = $false }
    }
    if ($sbxOnPath -and $sbxLoggedIn) {
        Write-Pass "sbx installed and logged in"
    } else {
        Write-Fail "sbx installed and logged in" "Install Docker Sandboxes and run 'sbx login'. See docs\participant-quickstart.md Step 1."
        Write-Host ""
        Write-Host "Cannot continue without sbx. Fix this first, then run this script again."
        exit 1
    }

    # 2. a sandbox starts
    $sandboxStarted = $false
    try {
        sbx create --name $SandboxName $Agent . 2>$null | Out-Null
        $sandboxStarted = $true
    } catch { $sandboxStarted = $false }

    if ($sandboxStarted) {
        Write-Pass "sandbox starts"
    } else {
        Write-Fail "sandbox starts" "Could not create a sandbox. Run 'sbx run $Agent' by hand in this folder to see the real error."
        exit 1
    }

    function Invoke-InSandbox($cmd) {
        return (sbx exec $SandboxName bash -lc $cmd)
    }

    # 3 & 4. agent choice + credentials present for the chosen lane
    if ($Agent -eq "opencode") {
        $keyPresent = $false
        try {
            Invoke-InSandbox 'test -n "${SURF_AIHUB_API_KEY:-}"' | Out-Null
            $keyPresent = $true
        } catch { $keyPresent = $false }

        if ($keyPresent) {
            Write-Pass "SURF AI Hub key found"
        } else {
            Write-Fail "SURF AI Hub key found" "Run 'sbx secret set-custom --host willma.surf.nl --env SURF_AIHUB_API_KEY' and paste the key from your invitation email."
            exit 1
        }
    } else {
        $claudeFound = $false
        try {
            Invoke-InSandbox 'command -v claude >/dev/null 2>&1' | Out-Null
            $claudeFound = $true
        } catch { $claudeFound = $false }

        if ($claudeFound) {
            Write-Pass "Claude Code found (sign in with your own subscription the first time you run it)"
        } else {
            Write-Fail "Claude Code found" "Claude Code isn't available inside the sandbox. See docs\troubleshooting.md."
            exit 1
        }
    }

    # 5. model responds to a trivial completion
    if ($Agent -eq "opencode") {
        $body = '{"model":"Sehyo/Qwen3.5-122B-A10B-NVFP4","messages":[{"role":"user","content":"reply with the word ok"}]}'
        $cmd = "curl -s -m 300 -o /dev/null -w '%{http_code}' -H \"Authorization: Bearer `$SURF_AIHUB_API_KEY`" -H 'Content-Type: application/json' -d '$body' https://willma.surf.nl/api/v0/chat/completions"
        $start = Get-Date
        $httpCode = "000"
        try { $httpCode = Invoke-InSandbox $cmd } catch { $httpCode = "000" }
        $elapsed = [int]((Get-Date) - $start).TotalSeconds

        if ($httpCode -eq "200") {
            Write-Pass "model responds"
        } else {
            Write-Fail "model responds" "The AI Hub did not return 200 (got $httpCode). Check the key hasn't expired, then see docs\troubleshooting.md."
            exit 1
        }

        if ($elapsed -gt $ColdStartSeconds) {
            Write-Note "model was cold (${elapsed}s to answer)" "Normal for the first request of the day -- on-demand models spin up on first use. Run this script again and it should answer in a couple of seconds."
        }
    } else {
        Write-Pass "model responds (Claude Code uses your own subscription, not checked here)"
    }

    # 6. model completes a tool call over a streaming request -- the check that matters most.
    if ($Agent -eq "opencode") {
        $toolBody = '{"model":"Sehyo/Qwen3.5-122B-A10B-NVFP4","stream":true,"tools":[{"type":"function","function":{"name":"get_time","description":"Get the current time","parameters":{"type":"object","properties":{}}}}],"messages":[{"role":"user","content":"What time is it? Use the get_time tool."}]}'
        $toolCmd = "curl -s -m 300 -H \"Authorization: Bearer `$SURF_AIHUB_API_KEY`" -H 'Content-Type: application/json' -d '$toolBody' https://willma.surf.nl/api/v0/chat/completions"
        $toolOutput = ""
        try { $toolOutput = Invoke-InSandbox $toolCmd } catch { $toolOutput = "" }

        if ($toolOutput -match "tool_calls") {
            Write-Pass "model can use tools (streaming)"
        } else {
            Write-Fail "model can use tools (streaming)" "The model did not return a tool call over a streaming request. This is the check that matters most -- contact the facilitator rather than retrying."
            exit 1
        }
    } else {
        Write-Pass "model can use tools (Claude Code manages this itself)"
    }

    # 7. skills load, count matches expectations
    $skillCount = (Get-ChildItem -Path ".claude\skills" -Filter "SKILL.md" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($skillCount -eq $ExpectedSkills) {
        Write-Pass "skills loaded ($skillCount)"
    } else {
        Write-Fail "skills loaded ($skillCount)" "Expected $ExpectedSkills skills in .claude\skills\. Try a fresh 'git clone' -- see docs\troubleshooting.md."
    }

    # 7b. git can actually reach GitHub from inside the sandbox. The sandbox's
    # network proxy needs a "github" secret configured before any git-over-
    # HTTPS traffic works -- even a plain clone of a public repo fails
    # without one.
    $sandboxGitOk = $false
    try {
        Invoke-InSandbox 'GIT_TERMINAL_PROMPT=0 timeout 20 git ls-remote https://github.com/surf-ori/agentic-tools >/dev/null 2>&1' | Out-Null
        $sandboxGitOk = $true
    } catch { $sandboxGitOk = $false }

    if ($sandboxGitOk) {
        Write-Pass "git can reach GitHub from inside the sandbox"
    } else {
        Write-Fail "git can reach GitHub from inside the sandbox" "Run 'sbx secret set github' and paste a GitHub personal access token (repo scope, from https://github.com/settings/tokens/new). Needed for the ori-ducklake MCP server and for submit.sh's git push."
    }

    # 8. git present, github.com reachable
    $gitOk = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $githubOk = $false
    try {
        $resp = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 10 -UseBasicParsing
        $githubOk = $true
    } catch { $githubOk = $false }

    if ($gitOk -and $githubOk) {
        Write-Pass "git and GitHub reachable"
    } else {
        Write-Fail "git and GitHub reachable" "Install git and make sure your network can reach github.com."
    }

    Write-Host ""
    if (-not $Failed) {
        Write-Host "All green. Reply to the invitation email with a screenshot of this output."
    } else {
        Write-Host "Something above needs fixing. Check docs\troubleshooting.md, then run this script again."
        exit 1
    }
} finally {
    Cleanup
}
