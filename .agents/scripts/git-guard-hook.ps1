param()

# Đọc context JSON truyền từ Antigravity qua stdin
$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
    $cmd = $payload.toolCall.args.CommandLine
} catch {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

if (-not $cmd) {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

# Danh sách Regex bắt các lệnh Git nguy hiểm
$dangerRegexList = @(
    'git\s+push\s+.*(-f\b|--force)',
    'git\s+push\s+.*--delete',
    'git\s+reset\s+--hard',
    'git\s+clean\s+-[a-zA-Z]*f',
    'git\s+checkout\s+(--\s+)?\.',
    'git\s+restore\s+(\.\b|--staged\s+\.)',
    'git\s+branch\s+-D',
    'git\s+reflog\s+expire',
    'git\s+prune',
    'git\s+gc\s+.*--prune'
)

foreach ($pattern in $dangerRegexList) {
    if ($cmd -match $pattern) {
        $blockedResponse = @{
            decision = "deny"
            reason   = "[HARD BLOCKED BY HOOK] Lệnh Git nguy hiểm bị cấm tuyệt đối theo chính sách an toàn: '$cmd'"
        } | ConvertTo-Json -Compress
        [Console]::Out.WriteLine($blockedResponse)
        exit 0
    }
}

# Lệnh an toàn
[Console]::Out.WriteLine('{"decision": "allow"}')
exit 0
