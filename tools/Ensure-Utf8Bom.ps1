<#
.SYNOPSIS
    Tự động kiểm tra và gắn UTF-8 with BOM cho các file AutoHotkey (.ahk).
.DESCRIPTION
    Script này quét các file .ahk (toàn bộ workspace hoặc chỉ các file đang được staged trong Git)
    và tự động ghi lại file với encoding UTF-8 có BOM (0xEF, 0xBB, 0xBF) nếu phát hiện file chưa có BOM.
.PARAMETER StagedOnly
    Chỉ kiểm tra và tự động 'git add' lại các file .ahk đang nằm trong Git staging area.
#>
param(
    [switch]$StagedOnly
)

$utf8WithBom = New-Object System.Text.UTF8Encoding($true)
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

if ($StagedOnly) {
    # Lấy danh sách các file .ahk đang staged (Added, Copied, Modified)
    $stagedFiles = git diff --cached --name-only --diff-filter=ACM
    $targetFiles = @($stagedFiles | Where-Object { $_ -like "*.ahk" })
} else {
    $targetFiles = @(Get-ChildItem -Path $repoRoot -Recurse -Filter *.ahk | Select-Object -ExpandProperty FullName)
}

if (-not $targetFiles -or $targetFiles.Count -eq 0) {
    exit 0
}

$fixedCount = 0

foreach ($relOrAbsPath in $targetFiles) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($relOrAbsPath)) {
        $relOrAbsPath
    } else {
        [System.IO.Path]::Combine($repoRoot, $relOrAbsPath)
    }

    if (Test-Path $fullPath) {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        
        if (-not $hasBom) {
            $text = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($fullPath, $text, $utf8WithBom)
            
            if ($StagedOnly) {
                git add "$relOrAbsPath"
            }
            
            Write-Host "[BOM Check] Đã tự động gắn UTF-8 with BOM cho: $relOrAbsPath" -ForegroundColor Yellow
            $fixedCount++
        }
    }
}

if ($fixedCount -gt 0) {
    Write-Host "[BOM Check] Đã đảm bảo UTF-8 with BOM cho $fixedCount file .ahk." -ForegroundColor Green
}
