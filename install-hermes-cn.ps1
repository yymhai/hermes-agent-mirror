# ============================================================================
# Hermes Agent 国内安装脚本 (Gitee 镜像版)
# ============================================================================
# 基于 https://gitee.com/qianchilang/hermes-agent 镜像（与 GitHub 上游完全一致）
# 默认开启国内镜像加速（清华 PyPI / npmmirror / 淘宝 Node+Playwright 镜像），不开代理也能装
#
# 用法（管理员 PowerShell 或普通 PowerShell 都可）：
#   iex (irm https://gitee.com/qianchilang/hermes-agent/raw/main/install-hermes-cn.ps1)
#
# 或下载后：
#   powershell -ExecutionPolicy Bypass -File install-hermes-cn.ps1
#
# 支持的参数（透传给官方 install.ps1）：
#   -SkipSetup          安装后不立即跑 hermes setup
#   -noVenv             不创建 Python venv
#   -Branch <name>      指定分支（默认 main）
#   -Commit <sha>       锁定到指定 commit
#   -Tag <tag>          锁定到指定 tag
#   -HermesHome <path>  自定义安装根目录
#
# Wrapper 自己的开关：
#   -NoMirror              关闭国内镜像加速（默认开启）
#   -SkipComputerUse       跳过 Computer Use 桌面操控工具（默认装，已走 Gitee 镜像 qianchilang/cua）
# ============================================================================

# 注意：不要加 [CmdletBinding()]，否则 PS 会严格校验参数，
# 未声明的 -SkipSetup/-Branch 等会被拒收。直接用 param 即可。
param(
    [switch]$NoMirror,
    [switch]$SkipComputerUse
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# --- 镜像地址 ----------------------------------------------------------------
$MirrorRepo    = "https://gitee.com/qianchilang/hermes-agent"
$MirrorRaw     = "$MirrorRepo/raw/main"
$InstallScript = "scripts/install.ps1"
$UpstreamRepo  = "github.com/NousResearch/hermes-agent"

# 国内包管理器镜像（默认启用）
$PyPiMirror        = "https://pypi.tuna.tsinghua.edu.cn/simple"
$NpmMirror         = "https://registry.npmmirror.com"
$NodeBinaryRoot    = "https://npmmirror.com/mirrors/node"
$PlaywrightMirror  = "https://npmmirror.com/mirrors/playwright"

# 输出编码设 UTF-8，避免乱码
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Hermes Agent 国内安装脚本 (Gitee 镜像)" -ForegroundColor Cyan
Write-Host "  镜像源: $MirrorRepo" -ForegroundColor DarkCyan
if (-not $NoMirror) {
    Write-Host "  加速: PyPI=$PyPiMirror  npm=$NpmMirror  node=$NodeBinaryRoot  playwright=$PlaywrightMirror" -ForegroundColor DarkCyan
}
if (-not $SkipComputerUse) {
    Write-Host "  包含: Computer Use 桌面操控（已走 Gitee 镜像 qianchilang/cua，跳过加 -SkipComputerUse）" -ForegroundColor DarkCyan
} else {
    Write-Host "  跳过: Computer Use (-SkipComputerUse)" -ForegroundColor DarkCyan
}
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. 下载官方 install.ps1（从 Gitee 镜像，速度快且稳定）--------------------
$tempScript = Join-Path $env:TEMP "hermes-install-cn.ps1"
Write-Host "[1/4] 正在从 Gitee 镜像下载安装脚本..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri "$MirrorRaw/$InstallScript" `
        -OutFile $tempScript -UseBasicParsing -TimeoutSec 60
} catch {
    throw "无法从 Gitee 镜像下载安装脚本: $_`n请检查网络后重试，或直接访问 https://gitee.com/qianchilang/hermes-agent"
}

Write-Host "      下载完成: $tempScript" -ForegroundColor Green

# --- 2. 把脚本里的 GitHub 仓库地址替换为 Gitee 镜像地址 ---------------------
Write-Host "[2/4] 切换仓库源到 Gitee 镜像..." -ForegroundColor Yellow

$scriptContent = Get-Content -Path $tempScript -Raw -Encoding UTF8

# HTTPS form: github.com/NousResearch/hermes-agent -> gitee.com/qianchilang/hermes-agent
$GiteeHost = "gitee.com/qianchilang/hermes-agent"
$scriptContent = $scriptContent.Replace($UpstreamRepo, $GiteeHost)

# SSH form: git@github.com:NousResearch/hermes-agent.git -> git@gitee.com:qianchilang/hermes-agent.git
$scriptContent = $scriptContent.Replace(
    "git@github.com:NousResearch/hermes-agent.git",
    "git@gitee.com:qianchilang/hermes-agent.git"
)

# trycua/cua (Computer Use driver): raw.githubusercontent.com/trycua/cua -> gitee.com/qianchilang/cua/raw
# 注意：保留路径里的 /main/ 分支名（Gitee mirror 也用 main）
$scriptContent = $scriptContent.Replace(
    "https://raw.githubusercontent.com/trycua/cua",
    "https://gitee.com/qianchilang/cua/raw"
)

Write-Host "      已将 github.com/NousResearch -> $GiteeHost" -ForegroundColor Green
Write-Host "      已将 git@github.com:NousResearch -> git@gitee.com:qianchilang" -ForegroundColor Green

# --- 3. 替换 Node.js 二进制下载源为淘宝镜像 ---------------------------------
# install.ps1 默认从 nodejs.org/dist 拉 Node 二进制，国内慢。npmmirror 路径格式兼容。
if (-not $NoMirror) {
    $nodeBefore = ([regex]::Matches($scriptContent, "nodejs\.org/dist")).Count
    $scriptContent = $scriptContent.Replace("https://nodejs.org/dist", $NodeBinaryRoot)
    if ($nodeBefore -gt 0) {
        Write-Host "      已将 https://nodejs.org/dist -> $NodeBinaryRoot ($nodeBefore 处)" -ForegroundColor Green
    }
}

# 写回临时文件（保持 UTF-8 BOM，PS 5.1 需要 BOM 才能正确解析含中文的脚本）
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($tempScript, $scriptContent, $utf8Bom)

# --- 4. 设置包管理器镜像环境变量 ---------------------------------------------
# uv / pip 通过 UV_INDEX_URL 走清华 PyPI；npm 走 npmmirror。
# 这些环境变量会被 install.ps1 启动的所有子进程（包括 uv sync / npm install）继承。
if (-not $NoMirror) {
    $env:UV_INDEX_URL            = $PyPiMirror
    $env:PIP_INDEX_URL           = $PyPiMirror
    $env:NPM_CONFIG_REGISTRY     = $NpmMirror
    $env:PLAYWRIGHT_DOWNLOAD_HOST = $PlaywrightMirror
    Write-Host "[3/4] 包管理器镜像已启用: UV_INDEX_URL, PIP_INDEX_URL, NPM_CONFIG_REGISTRY, PLAYWRIGHT_DOWNLOAD_HOST" -ForegroundColor Green
} else {
    Write-Host "[3/4] -NoMirror 已指定，使用官方源" -ForegroundColor Yellow
}

Write-Host "[4/4] 开始安装 Hermes Agent..." -ForegroundColor Yellow
Write-Host ""

# 收集透传给 install.ps1 的参数
$forwarded = @()
$PSBoundParameters.GetEnumerator() | ForEach-Object {
    # 跳过 PowerShell 公共参数和 wrapper 自己的参数
    if ($_.Key -in @("Verbose", "Debug", "ErrorAction", "WarningAction",
                     "InformationAction", "ProgressAction", "ErrorVariable",
                     "WarningVariable", "InformationVariable", "OutVariable",
                     "OutBuffer", "PipelineVariable", "NoMirror", "SkipComputerUse")) {
        return
    }
    $key = $_.Key
    $val = $_.Value
    if ($val -is [switch]) {
        if ($val.IsPresent) { $forwarded += "-$key" }
    } else {
        $forwarded += "-$key", "$val"
    }
}

# 默认装 Computer Use 桌面操控（不需要时加 -SkipComputerUse）
if ($SkipComputerUse) {
    $forwarded += "-SkipComputerUse"
}

& powershell -ExecutionPolicy Bypass -File $tempScript @forwarded
$exitCode = $LASTEXITCODE

# 清理
Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue

if ($exitCode -eq 0) {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  安装完成！输入 hermes 开始使用" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  安装失败，退出码: $exitCode" -ForegroundColor Red
    Write-Host "  查看上方报错信息，或访问 https://gitee.com/qianchilang/hermes-agent/issues" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
}

exit $exitCode
