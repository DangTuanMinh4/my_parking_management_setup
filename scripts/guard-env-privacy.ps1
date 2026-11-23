<#
.SYNOPSIS
    Hard Guard & Privacy Enforcer for Environment Files (.env / .env.*).
.DESCRIPTION
    Trien khai co che bao ve cung (Hard Security Guard) chong ro ri hoac doc file .env:
    1. Chan doc file .env qua PowerShell (ke ca khi dung -ErrorAction SilentlyContinue hoac pipeline).
    2. Kiem tra va kiem toan toan dien .aiignore, .gitignore, Git hooks va config permission.
    3. Cai dat Git pre-commit hook ngan chan commit file .env vao kho ma nguon.
    4. Cung cap che do -Test de xac minh tinh toan ven cua co che bao ve.
#>

[CmdletBinding(DefaultParameterSetName='Audit')]
param(
    [Parameter(ParameterSetName='Audit')]
    [switch]$Audit,

    [Parameter(ParameterSetName='Install')]
    [switch]$Install,

    [Parameter(ParameterSetName='EnforceSession')]
    [switch]$EnforceSession,

    [Parameter(ParameterSetName='Test')]
    [switch]$Test
)

$WorkspaceRoot = $PSScriptRoot | Split-Path -Parent

function Write-GuardHeader {
    param ([string]$Title)
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " [GUARD] $Title" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
}

function Test-IsSensitiveEnvPath {
    param ([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $clean = $Path.Trim().Replace('\', '/')
    $leaf = Split-Path -Leaf $clean

    # Whitelist template / example / documentation files
    if ($leaf -like "*.example*" -or $leaf -like "*template*" -or $leaf -like "*sample*") {
        return $false
    }

    # Blacklist any .env or .env.* file
    if ($leaf -eq ".env" -or $leaf -like ".env.*" -or $leaf -like "*.env" -or $leaf -like "*.env.*") {
        return $true
    }
    return $false
}

# ==============================================================================
# 1. HARD SESSION INTERCEPTOR (PowerShell Runtime Guard)
# ==============================================================================
function Enable-EnvPrivacySessionGuard {
    <#
    .DESCRIPTION
        Ghi de cmdlet Get-Content va Select-String trong phien PowerShell hien tai.
        Su dung "throw [System.Security.SecurityException]" de buoc phien dung ngay lap tuc
        ngay ca khi nguoi goi co tinh dung "-ErrorAction SilentlyContinue".
    #>
    Write-Host " [HARD-GUARD] Kich hoat bo chan doc file .env trong phien PowerShell..." -ForegroundColor Yellow

    # Proxy Get-Content
    function global:Get-Content {
        [CmdletBinding(DefaultParameterSetName='Path')]
        param(
            [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [string[]]$Path,
            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [string[]]$LiteralPath,
            [switch]$Raw,
            [int]$TotalCount,
            [object[]]$Filter,
            [object[]]$Include,
            [object[]]$Exclude,
            [Parameter(ValueFromRemainingArguments=$true)]
            $RemainingArgs
        )
        process {
            $checkList = @()
            if ($Path) { $checkList += $Path }
            if ($LiteralPath) { $checkList += $LiteralPath }

            foreach ($item in $checkList) {
                if (Test-IsSensitiveEnvPath -Path $item) {
                    throw [System.Security.SecurityException] "[STRICT ENV PRIVACY LOCK] Hard Guard Block: Doc noi dung file moi truong '$item' bi cam tuyet doi!"
                }
            }
            return Microsoft.PowerShell.Management\Get-Content @PSBoundParameters
        }
    }

    # Proxy Select-String
    function global:Select-String {
        [CmdletBinding(DefaultParameterSetName='File')]
        param(
            [Parameter(Position=0)]
            [object[]]$Pattern,
            [Parameter(Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
            [string[]]$Path,
            [Parameter(ValueFromPipelineByPropertyName=$true)]
            [string[]]$LiteralPath,
            [Parameter(ValueFromRemainingArguments=$true)]
            $RemainingArgs
        )
        process {
            $checkList = @()
            if ($Path) { $checkList += $Path }
            if ($LiteralPath) { $checkList += $LiteralPath }

            foreach ($item in $checkList) {
                if (Test-IsSensitiveEnvPath -Path $item) {
                    throw [System.Security.SecurityException] "[STRICT ENV PRIVACY LOCK] Hard Guard Block: Quet tim kiem trong file moi truong '$item' bi cam tuyet doi!"
                }
            }
            return Microsoft.PowerShell.Utility\Select-String @PSBoundParameters
        }
    }

    Write-Host " [HARD-GUARD] Da nap bo chan Get-Content & Select-String vao Global Scope thanh cong." -ForegroundColor Green
}

# ==============================================================================
# 2. AUDIT MECHANISM (Kiem tra toan bo hang rao bao ve)
# ==============================================================================
function Audit-EnvPrivacy {
    Write-GuardHeader "KIEM TOAN HE THONG BAO VE MOI TRUONG (STRICT ENV PRIVACY)"
    $issues = @()

    # 1. Kiem tra .aiignore tai root
    $rootAiIgnore = Join-Path $WorkspaceRoot ".aiignore"
    if (Test-Path $rootAiIgnore) {
        $content = Microsoft.PowerShell.Management\Get-Content -Path $rootAiIgnore -Raw
        $hasEnvWildcard = ($content -match '\*\*\/\.env\*' -or $content -match '\.env\*')
        $hasExampleAllowed = ($content -match '!\.env\.example')
        if (-not ($hasEnvWildcard -and $hasExampleAllowed)) {
            $issues += "[.aiignore Root] Thieu rule wildcard chan .env* hoac thieu allow .env.example"
        } else {
            Write-Host " [V] .aiignore (Root): Hop le va bao phu moi wildcard .env*" -ForegroundColor Green
        }
    } else {
        $issues += "[.aiignore Root] Khong tim thay file .aiignore o thu muc goc!"
    }

    # 2. Kiem tra .gitignore tai Frontend
    $feGitIgnore = Join-Path $WorkspaceRoot "parking_management_frontend\.gitignore"
    if (Test-Path $feGitIgnore) {
        $feContent = Microsoft.PowerShell.Management\Get-Content -Path $feGitIgnore -Raw
        $hasFeEnv = ($feContent -match '\.env\.\*')
        if (-not $hasFeEnv) {
            $issues += "[.gitignore Frontend] Thieu rule chan .env.*"
        } else {
            Write-Host " [V] .gitignore (Frontend): Da chan .env va .env.*" -ForegroundColor Green
        }
    }

    # 3. Kiem tra .gitignore tai Root
    $rootGitIgnore = Join-Path $WorkspaceRoot ".gitignore"
    if (Test-Path $rootGitIgnore) {
        $rootContent = Microsoft.PowerShell.Management\Get-Content -Path $rootGitIgnore -Raw
        if ($rootContent -match '\.env') {
            Write-Host " [V] .gitignore (Root): Da co rule chan .env" -ForegroundColor Green
        }
    } else {
        $issues += "[.gitignore Root] Chua co file .gitignore o thu muc goc."
    }

    # 4. Kiem tra Git Pre-Commit Hook tai Frontend
    $feHook = Join-Path $WorkspaceRoot "parking_management_frontend\.git\hooks\pre-commit"
    if (Test-Path $feHook) {
        $hookContent = Microsoft.PowerShell.Management\Get-Content -Path $feHook -Raw
        if ($hookContent -match "STRICT ENV PRIVACY LOCK") {
            Write-Host " [V] Git Hook (Frontend pre-commit): Da duoc cai dat va kich hoat." -ForegroundColor Green
        } else {
            $issues += "[Git Hook Frontend] pre-commit hook chua co logic STRICT ENV PRIVACY LOCK"
        }
    } else {
        $issues += "[Git Hook Frontend] Chua cai dat hook pre-commit!"
    }

    # 5. Kiem tra xem co file .env nao bi track boi Git khong
    Push-Location (Join-Path $WorkspaceRoot "parking_management_frontend")
    try {
        $trackedEnv = @(git ls-files "*env*" 2>$null | Where-Object { Test-IsSensitiveEnvPath $_ })
        if ($trackedEnv.Count -gt 0) {
            $issues += "[Git Tracking Frontend] Phat hien file .env da bi commit vao Git: $($trackedEnv -join ', ')"
        } else {
            Write-Host " [V] Git Index (Frontend): Khong co file .env that nao bi track." -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }

    # 6. Kiem tra check-before-merge.ps1
    $mergeScript = Join-Path $WorkspaceRoot "scripts\check-before-merge.ps1"
    if (Test-Path $mergeScript) {
        $scriptContent = Microsoft.PowerShell.Management\Get-Content -Path $mergeScript -Raw
        if ($scriptContent -match "STRICT ENV PRIVACY LOCK") {
            Write-Host " [V] scripts/check-before-merge.ps1: Da tich hop Hard Security Guard." -ForegroundColor Green
        } else {
            $issues += "[check-before-merge.ps1] Chua tich hop co che chan .env"
        }
    }

    Write-Host ""
    if ($issues.Count -gt 0) {
        Write-Host "========================================================================" -ForegroundColor Red
        Write-Host " PHAT HIEN CAC DIEM YEU BAO MAT CAN KHAC PHUC:" -ForegroundColor Red
        foreach ($iss in $issues) {
            Write-Host "   [!] $iss" -ForegroundColor Yellow
        }
        Write-Host "========================================================================" -ForegroundColor Red
        return $false
    } else {
        Write-Host "========================================================================" -ForegroundColor Green
        Write-Host " TAT CA CAC HANG RAO BAO VE MOI TRUONG DEU DA HOAT DONG HOAN HAO!" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Green
        return $true
    }
}

# ==============================================================================
# 3. SELF-TEST MECHANISM (Xac minh thuc te)
# ==============================================================================
function Run-EnvPrivacyTests {
    Write-GuardHeader "THUC THI UNIT TESTS XAC MINH HARD GUARD"
    Enable-EnvPrivacySessionGuard

    $allPassed = $true

    # Test 1: Get-Content .env voi -ErrorAction SilentlyContinue
    Write-Host " Test 1: Get-Content .env -ErrorAction SilentlyContinue... " -NoNewline
    $test1Blocked = $false
    try {
        $null = Get-Content -Path ".env" -ErrorAction SilentlyContinue
    } catch {
        if ($_.Exception.Message -match "STRICT ENV PRIVACY LOCK") {
            $test1Blocked = $true
        }
    }
    if ($test1Blocked) {
        Write-Host "PASS (Terminated by SecurityException)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (Did not block as expected!)" -ForegroundColor Red
        $allPassed = $false
    }

    # Test 2: Pipeline input ".env" | Get-Content -ErrorAction SilentlyContinue
    Write-Host " Test 2: Pipeline '.env' | Get-Content -ErrorAction SilentlyContinue... " -NoNewline
    $test2Blocked = $false
    try {
        $null = ".env" | Get-Content -ErrorAction SilentlyContinue
    } catch {
        if ($_.Exception.Message -match "STRICT ENV PRIVACY LOCK") {
            $test2Blocked = $true
        }
    }
    if ($test2Blocked) {
        Write-Host "PASS (Terminated by SecurityException)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (Did not block pipeline!)" -ForegroundColor Red
        $allPassed = $false
    }

    # Test 3: Select-String -Path ".env*"
    Write-Host " Test 3: Select-String -Path '.env' -ErrorAction SilentlyContinue... " -NoNewline
    $test3Blocked = $false
    try {
        $null = Select-String -Path ".env" -Pattern "SECRET" -ErrorAction SilentlyContinue
    } catch {
        if ($_.Exception.Message -match "STRICT ENV PRIVACY LOCK") {
            $test3Blocked = $true
        }
    }
    if ($test3Blocked) {
        Write-Host "PASS (Terminated by SecurityException)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (Did not block Select-String!)" -ForegroundColor Red
        $allPassed = $false
    }

    # Test 4: Cho phep doc file mau .env.example
    Write-Host " Test 4: Doc hop le file mau .env.example... " -NoNewline
    $test4Allowed = $false
    try {
        $examplePath = Join-Path $WorkspaceRoot ".env.example"
        if (Test-Path $examplePath) {
            $content = Get-Content -Path $examplePath -TotalCount 1
            $test4Allowed = $true
        } else {
            $test4Allowed = $true
        }
    } catch {
        $test4Allowed = $false
    }
    if ($test4Allowed) {
        Write-Host "PASS (Safe template readable)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (Template unexpectedly blocked!)" -ForegroundColor Red
        $allPassed = $false
    }

    # Test 5: Kiem tra ham Test-IsSensitiveEnvPath
    Write-Host " Test 5: Pattern matching danh gia file nhay cam... " -NoNewline
    $cases = @(
        @{ Path = ".env"; Expected = $true },
        @{ Path = ".env.local"; Expected = $true },
        @{ Path = ".env.production"; Expected = $true },
        @{ Path = "parking_management_frontend/.env"; Expected = $true },
        @{ Path = ".env.example"; Expected = $false },
        @{ Path = ".env.example.local"; Expected = $false },
        @{ Path = "src/config.js"; Expected = $false }
    )
    $patternPassed = $true
    foreach ($c in $cases) {
        $res = Test-IsSensitiveEnvPath $c.Path
        if ($res -ne $c.Expected) {
            $patternPassed = $false
            break
        }
    }
    if ($patternPassed) {
        Write-Host "PASS (All test cases correctly classified)" -ForegroundColor Green
    } else {
        Write-Host "FAIL (Pattern mismatch)" -ForegroundColor Red
        $allPassed = $false
    }

    Write-Host ""
    if ($allPassed) {
        Write-Host " [SUCCESS] 5/5 Hard Guard Tests PASSED!" -ForegroundColor Green
        return $true
    } else {
        Write-Host " [FAILURE] Some Hard Guard Tests FAILED!" -ForegroundColor Red
        return $false
    }
}

# ==============================================================================
# MAIN EXECUTION ROUTER
# ==============================================================================
if ($Test) {
    $ok = Run-EnvPrivacyTests
    exit $(if ($ok) { 0 } else { 1 })
} elseif ($EnforceSession) {
    Enable-EnvPrivacySessionGuard
} elseif ($Install) {
    Write-GuardHeader "INSTALLING HARD PRIVACY GUARDS"
    # Ensure hook is installed
    $hookSrc = Join-Path $PSScriptRoot "hooks\pre-commit"
    $hookDst = Join-Path $WorkspaceRoot "parking_management_frontend\.git\hooks\pre-commit"
    if (Test-Path $hookSrc) {
        Copy-Item -Path $hookSrc -Destination $hookDst -Force
        Write-Host " [V] Installed Git pre-commit hook to $hookDst" -ForegroundColor Green
    }
    Audit-EnvPrivacy
} else {
    $ok = Audit-EnvPrivacy
    exit $(if ($ok) { 0 } else { 1 })
}
