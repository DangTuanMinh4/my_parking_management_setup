param()

# Đọc context JSON truyền từ Antigravity tool hook qua stdin
$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json
    $toolName = $payload.toolCall.name
    $args = $payload.toolCall.args
} catch {
    [Console]::Out.WriteLine('{"decision": "allow"}')
    exit 0
}

# ==============================================================================
# GUARD 1: Kiểm soát run_command khi AI chạy Playwright E2E
# ==============================================================================
if ($toolName -eq "run_command" -and $args.CommandLine) {
    $cmd = $args.CommandLine

    # Kiểm tra xem lệnh có gọi playwright test hay không
    if ($cmd -match '\bplaywright\s+test\b') {
        
        # 1. Chặn lệnh chạy full suite không chỉ định mục tiêu (Targeted test)
        # Bắt buộc phải có file cụ thể (.spec.ts, .spec.js, .test.ts...) hoặc flag --grep / -g
        $hasTargetFile = ($cmd -match '\.(spec|test)\.(ts|js|mjs)\b')
        $hasGrep = ($cmd -match '(-g\b|--grep\b)')

        if (-not $hasTargetFile -and -not $hasGrep) {
            $denyResponse = @{
                decision = "deny"
                reason   = "[AGENT HOOK BLOCKED] Nghiêm cấm AI chạy toàn bộ test suite Playwright! Vui lòng chỉ định rõ file test cần chạy (ví dụ: 'tests/e2e/auth-guard.spec.js') hoặc flag --grep để tránh timeout và tràn token."
            } | ConvertTo-Json -Compress
            [Console]::Out.WriteLine($denyResponse)
            exit 0
        }

        # 2. Cấm flag --ui hoặc --headed (môi trường headless sandbox không có UI tương tác)
        if ($cmd -match '(--headed\b|--ui\b)') {
            $denyResponse = @{
                decision = "deny"
                reason   = "[AGENT HOOK BLOCKED] Không được dùng flag --headed hoặc --ui trong môi trường tự động của AI. Vui lòng chạy headless mặc định."
            } | ConvertTo-Json -Compress
            [Console]::Out.WriteLine($denyResponse)
            exit 0
        }
    }
}

# ==============================================================================
# GUARD 2: Kiểm soát edit_file / write_file trên kịch bản Playwright E2E
# ==============================================================================
if ($toolName -in @("edit_file", "write_file") -and $args.Path) {
    $filePath = [string]$args.Path
    $normalizedPath = $filePath.Replace('\', '/')

    # Chỉ can thiệp nếu sửa/ghi vào thư mục tests/e2e/
    if ($normalizedPath -match '/tests/e2e/') {
        $contentToCheck = ""
        if ($toolName -eq "edit_file" -and $args.Replacement) {
            $contentToCheck = [string]$args.Replacement
        } elseif ($toolName -eq "write_file" -and $args.Content) {
            $contentToCheck = [string]$args.Content
        }

        if (-not [string]::IsNullOrWhiteSpace($contentToCheck)) {
            # 1. Chặn sleep cứng ma thuật
            if ($contentToCheck -match 'page\.waitForTimeout\s*\(') {
                $denyResponse = @{
                    decision = "deny"
                    reason   = "[AGENT HOOK BLOCKED] Vi phạm AI Clean Code: Cấm tuyệt đối chèn 'page.waitForTimeout(...)'. Vui lòng dùng Web-First Assertions có auto-retry (như 'expect(locator).toBeVisible()') hoặc 'page.waitForResponse()'."
                } | ConvertTo-Json -Compress
                [Console]::Out.WriteLine($denyResponse)
                exit 0
            }

            # 2. Chặn gian lận bằng test.skip() hoặc test.fixme()
            if ($contentToCheck -match 'test\.(skip|fixme)\s*\(') {
                $denyResponse = @{
                    decision = "deny"
                    reason   = "[AGENT HOOK BLOCKED] Cấm tự ý chèn 'test.skip()' hoặc 'test.fixme()' để né tránh lỗi test. Nếu test fail, hãy sửa code logic hoặc cập nhật locator/assertion chuẩn xác."
                } | ConvertTo-Json -Compress
                [Console]::Out.WriteLine($denyResponse)
                exit 0
            }
        }
    }
}

# Cho phép thực thi bình thường nếu thỏa mãn điều kiện
[Console]::Out.WriteLine('{"decision": "allow"}')
exit 0
