@echo off
setlocal enabledelayedexpansion

:: =================================================================================
:: AMD 硬件加速转码脚本 - V15 (最终完善版)
:: 作者: Gemini & User Collaboration
:: 版本: 15.0
:: 日期: 2025-07-11
:: 更新: 增加了可选的码率控制功能，可完全控制输出文件的大小与质量。
::       这是功能最完整、运行最稳定的最终版本。
::
:: ★★ 重要提示: 请务必使用 "ANSI" 编码来保存此 .bat 文件! ★★
:: =================================================================================

echo.
echo =======================================================================
echo ==    AMD AMF 视频批量转码脚本 (V15 - 最终完善版)                     ==
echo =======================================================================
echo.

:: ################################################################################
:: #
:: #                            用户配置区域
:: #
:: ################################################################################

:: --- 1. 路径设置 ---
SET "sourceFolder=D:\testv"
SET "outputFolder=D:\testout"
SET "originalsFolder=D:\Original_Files_Backup"


:: --- 2. 视频编码模式 (二选一) ---
:: -> 使用 "rem" 来注释掉您不想使用的模式。默认使用A模式。

:: --- 模式A: 质量优先模式 (推荐) ---
:: 特点: 优先保证画面质量，文件大小会变化。是大多数情况下的最佳选择。
:: 可选值: speed (速度最快), balanced (均衡), quality (质量最高)
rem SET "qualityPreset=balanced"

:: --- 模式B: 体积优先 (码率控制) 模式 ---
:: 特点: 优先控制文件大小，画质会根据码率变化。适合对文件体积有严格要求的场景。
:: 使用方法: 取消本行的注释 (删除前面的 "rem")，并设置你想要的平均码率 (单位k)。
:: 码率参考: 1080p视频(4000k-8000k), 720p视频(2000k-4000k)
SET "bitrateControl=-b:v 2000k"


:: --- 3. 分辨率设置 ---
:: 留空表示保持原始分辨率。
:: 推荐用法: "-1:1080" (将高度设为1080p，宽度自动缩放)
SET "outputResolution="


:: --- 4. 音频处理设置 ---
:: 选项A: 直接复制 (速度最快，无损)
rem SET "audioCommand=-c:a copy"
:: 选项B: 重新编码为AAC (兼容性好，文件更小)
SET "audioCommand=-c:a aac -b:a 192k"


:: ################################################################################
:: #                      核心脚本逻辑 (通常无需修改)
:: ################################################################################

:: --- 路径净化与变量设置 ---
if "!sourceFolder:~-1!"=="\" SET "sourceFolder=!sourceFolder:~0,-1!"
SET "logFile=%~dp0completed_list.log"

:: --- 构建编码器设置命令 ---
if defined bitrateControl (
    SET "encoderSettings=%bitrateControl%"
) else (
    SET "encoderSettings=-quality %qualityPreset%"
)

:: --- 环境检查 ---
echo [INFO] 正在检查 FFmpeg 环境ing
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 未在系统路径中找到 ffmpeg.exe，请检查安装和环境变量。
    pause
    exit /b
)
echo [SUCCESS] FFmpeg 环境正常。
echo.

:: --- 创建文件夹 ---
if not exist "%outputFolder%" (mkdir "%outputFolder%")
if not exist "%originalsFolder%" (mkdir "%originalsFolder%")
if not exist "%logFile%" (type nul > "%logFile%")

:: --- 开始处理任务 ---
echo [PROCESS] 开始处理转码任务ing
echo.

:: --- 核心循环逻辑 ---
for /r "%sourceFolder%" %%I in (*.mkv, *.mp4, *.mov, *.avi, *.flv, *.webm) do (
    findstr /L /X /C:"%%I" "%logFile%" >nul
    if !errorlevel! equ 1 (
        set "fullPath=%%I"
        set "sourceFileDir=%%~dpI"
        set "baseName=%%~nI"
        set "fileExt=%%~xI"
        set "subDirs=!sourceFileDir:%sourceFolder%=!"
        if /i "!fileExt!"==".mkv" (set "outputExtension=.mkv") else (set "outputExtension=.mp4")
        set "finalOutputDir=%outputFolder%!subDirs!"
        set "outputFile=!finalOutputDir!!baseName!!outputExtension!"
        if not exist "!finalOutputDir!" mkdir "!finalOutputDir!"
        set "scaleFilterCommand="
        if not "!outputResolution%"=="" (set "scaleFilterCommand=-vf scale=!outputResolution!")

        echo ----------------------------------------------------------------------
        echo [CONVERTING] 正在转换: !baseName!!fileExt!
        echo [FROM]       源文件: !fullPath!
        echo [TO]         目标文件: !outputFile!
        echo ----------------------------------------------------------------------

        :: --- FFmpeg 核心命令 ---
        ffmpeg -hide_banner -hwaccel dxva2 -i "%%I" !scaleFilterCommand! -map 0 -c:v hevc_amf !encoderSettings! !audioCommand! -c:s copy -y "!outputFile!"

        if not !errorlevel! equ 0 (
            echo. & echo [ERROR] 转换失败: !baseName!!fileExt! & echo.
        ) else (
            echo.
            echo [SUCCESS] 成功转换: !baseName!!fileExt!
            set "backupDir=%originalsFolder%!subDirs!"
            set "backupFile=!backupDir!!baseName!!fileExt!"
            if not exist "!backupDir!" mkdir "!backupDir!"
            echo [MOVING] 正在移动源文件到备份目录ing
            move "%%I" "!backupFile!" >nul
            echo %%I >> "%logFile%"
            echo.
        )
    )
)
echo [PROCESS] 所有任务处理完毕。
:end
echo.
echo =======================================================================
echo ==                        脚本执行结束                               ==
echo =======================================================================
pause
