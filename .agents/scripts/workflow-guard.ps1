param()

$rawInput = [Console]::In.ReadToEnd()
if (-not $rawInput) {
    [Console]::Out.WriteLine('{"decision": "force_ask", "reason": "[CẢNH BÁO BẢO MẬT] Không nhận được context JSON từ IDE. Cần người dùng duyệt."}')
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
    $toolName = $payload.toolCall.name
} catch {
    [Console]::Out.WriteLine('{"decision": "force_ask", "reason": "[CẢNH BÁO BẢO MẬT] Lỗi giải mã context hook. Cần người dùng duyệt."}')
    exit 0
}

if ($toolName -eq "run_workflow") {
    $response = @{
        decision = "force_ask"
        reason   = "[CẢNH BÁO AN TOÀN] AI đang yêu cầu thực thi script run_workflow. Bạn có đồng ý cho phép thực thi script này không?"
    } | ConvertTo-Json -Compress

    [Console]::Out.WriteLine($response)
    exit 0
}

[Console]::Out.WriteLine('{"decision": "allow"}')
exit 0
