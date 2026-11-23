param()

# Ensure telemetry directory exists
$telemetryDir = "E:\code\parking_management\.agents\telemetry"
if (-not (Test-Path $telemetryDir)) {
    New-Item -ItemType Directory -Path $telemetryDir -Force | Out-Null
}
$eventsFile = Join-Path $telemetryDir "events.json"

# Read pipeline input if present
$rawInput = ""
if ($input) {
    $rawInput = ($input | Out-String)
}

try {
    $payload = $null
    if ($rawInput -and $rawInput.Trim().Length -gt 0) {
        $payload = $rawInput | ConvertFrom-Json
    }

    $toolName = ""
    $argsObj = $null
    if ($payload -and $payload.toolCall) {
        $toolName = $payload.toolCall.name
        $argsObj = $payload.toolCall.args
    }

    # Live dynamic worktrees from git
    $worktrees = @()
    try {
        $rawWt = git worktree list --porcelain
        $currentPath = ""
        $currentHead = ""
        $currentBranch = ""

        foreach ($line in ($rawWt -split "`r?`n")) {
            if ($line -like "worktree *") {
                $currentPath = $line.Substring(9).Trim()
            } elseif ($line -like "HEAD *") {
                $currentHead = $line.Substring(5).Trim()
            } elseif ($line -like "branch *") {
                $currentBranch = $line.Substring(7).Trim()
                $worktrees += [PSCustomObject]@{
                    path = $currentPath
                    head = $currentHead
                    branch = $currentBranch
                }
                $currentPath = ""
                $currentHead = ""
                $currentBranch = ""
            }
        }
    } catch {}

    $telemetry = [PSCustomObject]@{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        eventName = if ($payload) { $payload.hookEventName } else { "Sync" }
        conversationId = if ($payload) { $payload.conversationId } else { "" }
        toolName = $toolName
        toolArgs = $argsObj
        worktrees = $worktrees
    }

    $telemetry | ConvertTo-Json -Depth 6 | Set-Content -Path $eventsFile -Encoding UTF8
} catch {}

Write-Output '{"decision": "allow"}'
