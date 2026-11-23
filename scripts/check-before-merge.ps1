<#
.SYNOPSIS
    Pre-merge audit script for multi-repo workspace (Frontend & Backend).
.DESCRIPTION
    Kiem tra trang thai Git (Branch diff, Staged diff, Unstaged/Untracked files)
    tren ca 2 repository truoc khi thuc hien merge.
    TUAN THU: Chi doc trang thai (Read-Only), khong tu y checkout, reset, stash hay merge.
#>

[CmdletBinding()]
param (
    [string]$TargetBranch = "main",
    [switch]$DetailedDiff,
    [switch]$NonInteractive
)

# ==============================================================================
# 1. UI HELPER FUNCTIONS (Tach cac phan Write-Host lap lai)
# ==============================================================================

function Write-SectionHeader {
    param ([string]$Title)
    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Cyan
    Write-Host ("   {0,-50}" -f $Title) -ForegroundColor Cyan
    Write-Host "=======================================================" -ForegroundColor Cyan
}

function Write-SubHeader {
    param ([string]$Title)
    Write-Host ""
    Write-Host "-------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ">> $Title" -ForegroundColor Cyan
    Write-Host "-------------------------------------------------------" -ForegroundColor DarkGray
}

function Write-SuccessMessage {
    param ([string]$Message)
    Write-Host " [V] $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param ([string]$Message)
    Write-Host " [!] $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param ([string]$Message)
    Write-Host " [X] $Message" -ForegroundColor Red
}

function Write-FileStatusList {
    param (
        [string[]]$Files,
        [ConsoleColor]$Color = [ConsoleColor]::DarkGray,
        [string]$Prefix = ""
    )
    foreach ($file in $Files) {
        if (-not [string]::IsNullOrWhiteSpace($file)) {
            Write-Host "       $Prefix$file" -ForegroundColor $Color
        }
    }
}

function Write-DiffStatusList {
    param ([string[]]$DiffEntries)
    foreach ($entry in $DiffEntries) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $statusCode = $entry.Substring(0, 1)
        $color = switch ($statusCode) {
            "A" { [ConsoleColor]::Green }
            "M" { [ConsoleColor]::Yellow }
            "D" { [ConsoleColor]::Red }
            Default { [ConsoleColor]::White }
        }
        Write-Host "     $entry" -ForegroundColor $color
    }
}

# ==============================================================================
# 2. GIT DOMAIN HELPER FUNCTIONS (Tach logic & bieu thuc dieu kien thanh ham)
# ==============================================================================

function Get-RepoGitStatus {
    return [PSCustomObject]@{
        Unstaged  = @(git diff --name-status)
        Staged    = @(git diff --cached --name-status)
        Untracked = @(git ls-files --others --exclude-standard)
    }
}

function Test-HasUncommittedChanges {
    param ($Status)
    $hasUnstaged  = ($Status.Unstaged.Count -gt 0)
    $hasStaged    = ($Status.Staged.Count -gt 0)
    $hasUntracked = ($Status.Untracked.Count -gt 0)
    return ($hasUnstaged -or $hasStaged -or $hasUntracked)
}

function Resolve-TargetBranchReference {
    param ([string]$Branch)
    $isLocalBranchExist  = [bool](git rev-parse --verify $Branch 2>$null)
    if ($isLocalBranchExist) {
        return $Branch
    }

    $remoteCandidate     = "origin/$Branch"
    $isRemoteBranchExist = [bool](git rev-parse --verify $remoteCandidate 2>$null)
    if ($isRemoteBranchExist) {
        return $remoteCandidate
    }

    return $null
}

function Get-CommitDivergence {
    param ([string]$TargetRef)
    $revCountRaw = (git rev-list --left-right --count "$TargetRef...HEAD" 2>$null | Out-String).Trim()
    if (-not $revCountRaw) {
        return @{ Behind = 0; Ahead = 0 }
    }
    $parts = $revCountRaw -split '\s+'
    return @{
        Behind = [int]$parts[0]
        Ahead  = [int]$parts[1]
    }
}

function Test-IsSensitiveEnvFile {
    param ([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $cleanPath = $Path.Trim().Replace('\', '/')
    $fileName = Split-Path -Leaf $cleanPath

    # Allow safe templates/examples
    if ($fileName -like "*.example*" -or $fileName -like "*template*" -or $fileName -like "*sample*") {
        return $false
    }

    # Block any .env or .env.* variant
    if ($fileName -eq ".env" -or $fileName -like ".env.*" -or $fileName -like "*.env" -or $fileName -like "*.env.*") {
        return $true
    }
    return $false
}

function Get-SensitiveEnvViolationsInRepo {
    $violations = @()

    # 1. Staged files
    $staged = @(git diff --cached --name-only)
    foreach ($f in $staged) {
        if (Test-IsSensitiveEnvFile $f) {
            $violations += [PSCustomObject]@{ File = $f; Scope = "STAGED (dang chuan bi commit)" }
        }
    }

    # 2. Tracked files in index
    $tracked = @(git ls-files "*env*")
    foreach ($f in $tracked) {
        if (Test-IsSensitiveEnvFile $f) {
            $violations += [PSCustomObject]@{ File = $f; Scope = "TRACKED (da bi luu vao Git)" }
        }
    }

    # 3. Untracked files (neu chua duoc gitignore dung cach)
    $untracked = @(git ls-files --others --exclude-standard)
    foreach ($f in $untracked) {
        if (Test-IsSensitiveEnvFile $f) {
            $violations += [PSCustomObject]@{ File = $f; Scope = "UNTRACKED (chua duoc ignore boi .gitignore)" }
        }
    }

    return $violations
}

# ==============================================================================
# 3. CHINH: DIEU PHOI KIEM TRA TREN CAC REPOSITORIES
# ==============================================================================

$WorkspaceRoot = $PSScriptRoot | Split-Path -Parent
$Repos = @(
    @{ Name = "Frontend"; Path = (Join-Path $WorkspaceRoot "parking_management_frontend") },
    @{ Name = "Backend";  Path = (Join-Path $WorkspaceRoot "parking_management_backend") }
)

Write-SectionHeader "SMART MOBILITY - PRE-MERGE HEALTH CHECK"
Write-Host "Nhanh dich kiem tra: " -NoNewline
Write-Host "$TargetBranch" -ForegroundColor Yellow

$HasAnomalies = $false
$HasSecurityBlock = $false
$RepoSummaries = @()

foreach ($repo in $Repos) {
    Write-SubHeader "KIEM TRA: $($repo.Name) ($($repo.Path))"

    # Semantic Guard: Kiem tra su ton tai cua thu muc & Git repo
    $isFolderMissing = (-not (Test-Path $repo.Path))
    if ($isFolderMissing) {
        Write-ErrorMessage "Khong tim thay thu muc: $($repo.Path)"
        $HasAnomalies = $true
        continue
    }

    $isGitRepo = (Test-Path (Join-Path $repo.Path ".git"))
    if (-not $isGitRepo) {
        Write-ErrorMessage "Thu muc khong phai la Git repository."
        $HasAnomalies = $true
        continue
    }

    Push-Location $repo.Path
    try {
        # 1. Kiem tra branch hien tai
        $branchOutput = (git branch --show-current 2>&1 | Out-String).Trim()
        $isBranchQueryFailed = ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branchOutput) -or $branchOutput -match "^fatal:")
        
        if ($isBranchQueryFailed) {
            Write-ErrorMessage "Loi khi doc trang thai Git hoac branch:"
            Write-Host "     $branchOutput" -ForegroundColor DarkYellow
            
            $isDubiousOwnership = ($branchOutput -match "dubious ownership")
            if ($isDubiousOwnership) {
                Write-WarningMessage "Phat hien loi safe.directory tren Windows. Chay lenh sau de bo qua:"
                Write-Host "     git config --global --add safe.directory '$($repo.Path.Replace('\', '/'))'" -ForegroundColor White
            }
            $HasAnomalies = $true
            $RepoSummaries += [PSCustomObject]@{
                Repo   = $repo.Name
                Branch = "Loi Git"
                Status = "Loi"
            }
            continue
        }

        $currentBranch = $branchOutput
        Write-Host " Branch hien tai: " -NoNewline
        Write-Host "$currentBranch" -ForegroundColor Green

        # 1.1 KHOA BAO MAT CUNG: Kiem tra ro ri file .env/secrets (STRICT ENV PRIVACY LOCK)
        $envViolations = Get-SensitiveEnvViolationsInRepo
        if ($envViolations.Count -gt 0) {
            Write-ErrorMessage "!!! VI PHAM BAO MAT NGHIEP TRONG: PHAT HIEN FILE .ENV TRONG REPO !!!"
            foreach ($v in $envViolations) {
                Write-Host "       [HARD-BLOCKED] $($v.File) -> $($v.Scope)" -ForegroundColor Red
            }
            $HasAnomalies = $true
            $HasSecurityBlock = $true
        }

        # 2. Kiem tra Working tree (Staged / Unstaged / Untracked)
        $gitStatus = Get-RepoGitStatus
        $hasDirtyWorktree = Test-HasUncommittedChanges -Status $gitStatus

        if ($hasDirtyWorktree) {
            $HasAnomalies = $true
            Write-WarningMessage "Working tree chua sach (con code chua commit):"
            
            $hasUnstaged = ($gitStatus.Unstaged.Count -gt 0)
            if ($hasUnstaged) {
                Write-Host "   - Unstaged files (da sua nhung chua stage):" -ForegroundColor DarkYellow
                Write-FileStatusList -Files $gitStatus.Unstaged -Color DarkGray
            }

            $hasStaged = ($gitStatus.Staged.Count -gt 0)
            if ($hasStaged) {
                Write-Host "   - Staged files (da add nhung chua commit):" -ForegroundColor Magenta
                Write-FileStatusList -Files $gitStatus.Staged -Color DarkGray
            }

            $hasUntracked = ($gitStatus.Untracked.Count -gt 0)
            if ($hasUntracked) {
                Write-Host "   - Untracked files (file moi chua duoc git quan ly):" -ForegroundColor Blue
                Write-FileStatusList -Files $gitStatus.Untracked -Color DarkGray -Prefix "? "
            }
        } else {
            Write-SuccessMessage "Working tree sach (Khong co uncommitted changes)"
        }

        # 3. So sanh voi TargetBranch
        Write-Host ""
        Write-Host " So sanh voi nhanh dich '$TargetBranch':" -ForegroundColor Cyan
        
        $resolvedTarget = Resolve-TargetBranchReference -Branch $TargetBranch
        $isTargetMissing = [string]::IsNullOrEmpty($resolvedTarget)

        if ($isTargetMissing) {
            Write-ErrorMessage "Khong tim thay nhanh dich '$TargetBranch' tren ca local va remote origin."
            $HasAnomalies = $true
        } else {
            $isDirectlyOnTarget = ($currentBranch -eq $resolvedTarget)
            if ($isDirectlyOnTarget) {
                Write-WarningMessage "Ban dang dung truc tiep tren nhanh dich '$currentBranch'."
            } else {
                # Kiem tra do lech commit Ahead / Behind
                $divergence = Get-CommitDivergence -TargetRef $resolvedTarget
                $isBehindTarget = ($divergence.Behind -gt 0)
                $behindColor = if ($isBehindTarget) { [ConsoleColor]::Red } else { [ConsoleColor]::DarkGray }

                Write-Host "   Tien do commit: " -NoNewline
                Write-Host "Ahead: $($divergence.Ahead) commit(s)" -ForegroundColor Green -NoNewline
                Write-Host " | " -NoNewline
                Write-Host "Behind: $($divergence.Behind) commit(s)" -ForegroundColor $behindColor

                if ($isBehindTarget) {
                    Write-WarningMessage "Nhanh hien tai dang tut lai $($divergence.Behind) commit so voi $resolvedTarget. Can rebase/merge som!"
                    $HasAnomalies = $true
                }

                # Diff thong ke file va dong code
                $branchDiffStatus = @(git diff --name-status "$resolvedTarget...HEAD")
                $branchDiffStat   = @(git diff --stat "$resolvedTarget...HEAD")
                $hasDiffChanges   = ($branchDiffStatus.Count -gt 0)

                # Kiem tra xem branch co chua commit sua doi file .env khong
                $branchDiffFiles = @(git diff --name-only "$resolvedTarget...HEAD")
                $branchEnvFiles = @($branchDiffFiles | Where-Object { Test-IsSensitiveEnvFile $_ })
                if ($branchEnvFiles.Count -gt 0) {
                    Write-ErrorMessage "VI PHAM BAO MAT: Phat hien commit thay doi file .env nhay cam:"
                    foreach ($f in $branchEnvFiles) {
                        Write-Host "       [HARD-BLOCKED COMMIT DIFF] $f" -ForegroundColor Red
                    }
                    $HasAnomalies = $true
                    $HasSecurityBlock = $true
                }

                if ($hasDiffChanges) {
                    Write-Host "`n   Danh sach file thay doi ($resolvedTarget...HEAD):" -ForegroundColor Cyan
                    Write-DiffStatusList -DiffEntries $branchDiffStatus

                    Write-Host "`n   Thong ke dong code:" -ForegroundColor DarkCyan
                    $branchDiffStat | ForEach-Object { Write-Host "     $_" -ForegroundColor DarkGray }

                    if ($DetailedDiff) {
                        Write-Host "`n   [Chi tiet Diff (Sanitized - Loai bo .env)]: " -ForegroundColor DarkYellow
                        git diff "$resolvedTarget...HEAD" -- ":(exclude)*.env*" ":(exclude)**/.env*"
                    }
                } else {
                    Write-Host "   Khong co thay doi code nao giua '$currentBranch' va '$resolvedTarget'." -ForegroundColor DarkGray
                }
            }
        }

        $repoStatusText = if ($hasDirtyWorktree) { "Chua commit het file" } else { "Sach" }
        $RepoSummaries += [PSCustomObject]@{
            Repo   = $repo.Name
            Branch = $currentBranch
            Status = $repoStatusText
        }
    }
    finally {
        Pop-Location
    }
}

# ==============================================================================
# 4. TONG KET VA XAC NHAN THU CONG
# ==============================================================================

Write-SectionHeader "TONG KET KIEM TRA"

foreach ($item in $RepoSummaries) {
    $isClean = ($item.Status -eq "Sach")
    $statusColor = if ($isClean) { [ConsoleColor]::Green } else { [ConsoleColor]::Yellow }
    Write-Host " * $($item.Repo) (Branch: $($item.Branch)): " -NoNewline
    Write-Host $item.Status -ForegroundColor $statusColor
}

Write-Host ""
if ($HasSecurityBlock) {
    Write-Host "=======================================================" -ForegroundColor Red
    Write-Host "   KHOA BAO MAT CUNG: MERGE BI CHAN HOAN TOAN!        " -ForegroundColor Red
    Write-Host "=======================================================" -ForegroundColor Red
    Write-ErrorMessage "Phat hien file .env/secrets nhay cam trong repository hoac commit diff!"
    Write-ErrorMessage "STRICT ENV PRIVACY LOCK nghiem cam commit/merge file .env that."
    Write-Host "  Khac phuc: Go bo khoi Git staging/index va them vao .gitignore!" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if ($HasAnomalies) {
    Write-WarningMessage "Phat hien bat thuong, working tree chua sach hoac co loi Git."
    Write-Host "  Khuyen nghi: Rasoat lai commit hoac giai quyet xung dot truoc khi merge!" -ForegroundColor DarkYellow
} else {
    Write-SuccessMessage "Trang thai ca 2 repository da san sang de merge."
}

Write-Host ""
if ($NonInteractive) {
    Write-Host "[NON-INTERACTIVE] Ket thuc kiem tra. Khong hoi xac nhan console." -ForegroundColor DarkGray
} else {
    $confirm = Read-Host "Ban co muon tiep tuc buoc merge thu cong khong? (y/N)"
    $isConfirmed = ($confirm -match '^[Yy]$')

    if ($isConfirmed) {
        Write-SuccessMessage "Ban da dong y. Hay thuc hien git merge thu cong tren repo can merge."
        Write-Host ""
    } else {
        Write-WarningMessage "Da dung quy trinh. Chua co thao tac merge nao duoc thuc hien."
        Write-Host ""
    }
}
