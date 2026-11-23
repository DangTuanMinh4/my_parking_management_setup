param()

# Đọc context JSON truyền từ Antigravity qua stdin
$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
    $toolName = $payload.toolCall.name
    $cmd = $payload.toolCall.args.CommandLine
} catch {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

if (-not $cmd) {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

# ==============================================================================
# GUARD: Chặn các câu lệnh script (Python, Node, PowerShell, CMD) xóa/sửa/ghi file
# ==============================================================================
# Danh sách Regex bắt hành vi sửa/xóa/ghi đè file mã nguồn qua script dòng lệnh
$forbiddenPatterns = @(
    # Python file deletion / overwriting
    'python.*(\bos\.remove\b|\bos\.unlink\b|\bshutil\.rmtree\b|\bshutil\.move\b)',
    'python.*(\bopen\s*\(.*[\''\"][wa\+]|\bPath\(.*\.unlink\(|\bPath\(.*\.write_text\(|\bPath\(.*\.write_bytes\()',
    
    # Node inline file deletion / writing
    'node\s+-e.*(\bfs\.unlink\b|\bfs\.rm\b|\bfs\.rmdir\b|\bfs\.writeFileSync\b|\bfs\.writeFile\b|\bfs\.promises\.unlink\b)',
    
    # PowerShell destructive file cmdlets
    '\b(Remove-Item|ri|del|erase|rmdir|rd)\b.*(\.js|\.jsx|\.ts|\.tsx|\.py|\.mjs|\.json|\.md|\.css|\.html)\b',
    '\b(Set-Content|sc|Add-Content|ac|Out-File)\b.*(\.js|\.jsx|\.ts|\.tsx|\.py|\.mjs|\.json|\.md|\.css|\.html)\b',
    
    # Direct shell redirection overwriting code files
    '>\s*([a-zA-Z0-9_\-\./\\]+\.(js|jsx|ts|tsx|py|mjs|json|md|css|html))\b',
    '>>\s*([a-zA-Z0-9_\-\./\\]+\.(js|jsx|ts|tsx|py|mjs|json|md|css|html))\b'
)

foreach ($pattern in $forbiddenPatterns) {
    if ($cmd -match $pattern) {
        $blockedResponse = @{
            decision = "deny"
            reason   = "[HARD BLOCKED BY SCRIPT-WRITE-GUARD] Phát hiện lệnh can thiệp sửa/xóa/ghi đè file mã nguồn qua dòng lệnh ('$cmd'). Theo quy tắc AI Clean Code & Native Edit Guard: MỌI sửa đổi file BẮT BUỘC dùng edit_file / write_file để người dùng theo dõi Visual Diff trực quan!"
        } | ConvertTo-Json -Compress
        [Console]::Out.WriteLine($blockedResponse)
        exit 0
    }
}

# Lệnh an toàn
[Console]::Out.WriteLine('{"decision": "allow"}')
exit 0
