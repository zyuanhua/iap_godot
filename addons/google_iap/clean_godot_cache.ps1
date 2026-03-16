# Godot 缓存清理脚本
# 用于解决语言切换缓存问题

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Godot 缓存清理工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "d:\work\trae\plug-in\iap"
$addonPath = "$projectPath\addons\google_iap"

Write-Host "项目路径：$projectPath" -ForegroundColor Yellow
Write-Host ""

# 步骤 1：检查 Godot 是否运行
Write-Host "[步骤 1] 检查 Godot 是否运行..." -ForegroundColor Yellow
$godotProcess = Get-Process godot* -ErrorAction SilentlyContinue
if ($godotProcess) {
    Write-Host "⚠️  警告：Godot 正在运行！" -ForegroundColor Red
    Write-Host "   请先关闭 Godot 编辑器，然后按任意键继续..." -ForegroundColor Red
    pause
} else {
    Write-Host "✓ Godot 未运行，继续..." -ForegroundColor Green
}
Write-Host ""

# 步骤 2：删除 .godot 缓存
Write-Host "[步骤 2] 删除 .godot 缓存文件夹..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.godot") {
    Remove-Item -Recurse -Force "$projectPath\.godot"
    Write-Host "✓ 已删除 .godot 文件夹" -ForegroundColor Green
} else {
    Write-Host "ℹ️  .godot 文件夹不存在" -ForegroundColor Cyan
}
Write-Host ""

# 步骤 3：删除 .import 缓存
Write-Host "[步骤 3] 删除 .import 文件夹..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.import") {
    Remove-Item -Recurse -Force "$projectPath\.import"
    Write-Host "✓ 已删除 .import 文件夹" -ForegroundColor Green
} else {
    Write-Host "ℹ️  .import 文件夹不存在" -ForegroundColor Cyan
}
Write-Host ""

# 步骤 4：清理备份文件
Write-Host "[步骤 4] 清理备份文件..." -ForegroundColor Yellow
$backupFiles = Get-ChildItem -Path $addonPath -Filter "*.backup*" -ErrorAction SilentlyContinue
if ($backupFiles) {
    foreach ($file in $backupFiles) {
        Remove-Item $file.FullName -Force
        Write-Host "✓ 已删除：$($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "ℹ️  没有备份文件" -ForegroundColor Cyan
}
Write-Host ""

# 步骤 5：清理 Python 脚本
Write-Host "[步骤 5] 清理临时 Python 脚本..." -ForegroundColor Yellow
$pyFiles = Get-ChildItem -Path $addonPath -Filter "*.py" -ErrorAction SilentlyContinue
if ($pyFiles) {
    foreach ($file in $pyFiles) {
        Remove-Item $file.FullName -Force
        Write-Host "✓ 已删除：$($file.Name)" -ForegroundColor Green
    }
} else {
    Write-Host "ℹ️  没有 Python 脚本" -ForegroundColor Cyan
}
Write-Host ""

# 完成
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ 缓存清理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 重新打开 Godot 编辑器" -ForegroundColor White
Write-Host "2. 打开项目：$projectPath" -ForegroundColor White
Write-Host "3. 等待 Godot 重新导入所有资源" -ForegroundColor White
Write-Host "4. 测试语言切换功能" -ForegroundColor White
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Cyan
pause
