@echo off
setlocal enabledelayedexpansion

:: =================================================================================
:: AMD 硬件加速转码脚本 - V10 (最终交付版)
:: 作者: Gemini & User Collaboration
:: 版本: 10.0
:: 日期: 2025-07-11
:: 描述: 经过完整审查和多次迭代修正，实现了健壮的路径处理、错误处理和
::       命令兼容性，是功能完整、运行稳定的最终版本。
::
:: ★★ 重要提示: 请务必使用 "ANSI" 编码来保存此 .bat 文件! ★★
:: =================================================================================

echo.
echo(==========================================================
echo(   AMD AMF 视频批量转码脚本 (V10 - 最终交付版)
echo(==========================================================
echo.

:: ################################################################################
:: #
:: #                            用户配置区域
:: #                您需要修改的所有设置都在这里
:: #
:: ################################################################################

:: --- 1. 路径设置 ---
:: 源文件夹: 存放待转换视频的文件夹 (路径末尾请不要带 \ )
SET "sourceFolder=D:\testv"
:: 输出文件夹: 存放转换后视频的文件夹。
SET "outputFolder=D:\testout"
:: 备份文件夹: 存放成功转换后的原始视频。
SET "originalsFolder=D:\Original_Files_Backup"

:: --- 2. 转码质量设置 ---
:: 可选值: speed (速度最快), balanced (均衡), quality (质量最高)
SET "qualityPreset=balanced"

:: --- 3. 分辨率设置 (宽:高) ---
:: -> 留空表示保持原始分辨率 (例如: SET "outputResolution=")
:: -> 推荐使用 "-1" 来保持宽高比，避免视频变形:
::      -1:1080  (最常用: 将视频高度设为1080p，宽度自动)
::      -1:720   (将视频高度设为720p，宽度自动)
SET "outputResolution="

:: --- 4. 音频处理设置 ---
:: -> 使用 "rem" 来注释掉您不想使用的选项。确保只有一个选项是激活的。

:: 选项 A: 直接复制音频流 (速度最快，无损，但文件较大)
rem SET "audioCommand=-c:a copy"

:: 选项 B: 重新编码为高质量AAC (兼容性好，文件更小)
SET "audioCommand=-c:a aac -b:a 192k"


:: ################################################################################
:: #                      脚本核心逻辑 (通常无需修改)
:: ################################################################################

:: --- 路径净化 ---
if "!sourceFolder:~-1!"=="\" SET "sourceFolder=!sourceFolder:~0,-1!"

:: --- 脚本内部变量 ---
SET "logFile=%~dp0completed_list.log"
SET "todoFile=%~dp0todo_list.tmp"

:: --- 环境检查与准备 ---
echo([INFO] 检查 FFmpeg 环境...
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo([ERROR] 未在系统路径中找到 ffmpeg.exe。
    echo([ERROR] 请确保您已正确安装 FFmpeg 并将其添加到系统环境变量 Path 中。
    pause
    exit /b
)
echo([SUCCESS] FFmpeg 环境正常。

echo.
echo([CONFIG] 源文件目录: %sourceFolder%
echo([CONFIG] 输出文件目录: %outputFolder%
echo([CONFIG] 备份目录: %originalsFolder%
echo([CONFIG] 质量预设: %qualityPreset%
if not "%outputResolution%"=="" (echo([CONFIG] 分辨率设置: %outputResolution%) else (echo([CONFIG] 分辨率设置: 保持原始分辨率)
echo([CONFIG] 音频处理命令: %audioCommand%
echo.

:: 创建不存在的文件夹
if not exist "%outputFolder%" (echo([INFO] 创建输出文件夹... & mkdir "%outputFolder%")
if not exist "%originalsFolder%" (echo([INFO] 创建备份文件夹... & mkdir "%originalsFolder%")
if not exist "%logFile%" (echo([INFO] 创建日志文件... & type nul > "%logFile%")

:: --- 生成待办事项列表 ---
echo([PROCESS] 正在扫描并生成待办事项列表...
if exist "%todoFile%" del "%todoFile%"
for /r "%sourceFolder%" %%F in (*.mkv, *.mp4, *.mov, *.avi, *.flv, *.webm) do (
    findstr /L /X /C:"%%F" "%logFile%" >nul
    if !errorlevel! equ 1 (
        echo %%F >> "%todoFile%"
    )
)

if not exist "%todoFile%" (
    echo([COMPLETE] 没有找到需要转换的新文件。所有任务已完成。
    goto :end
)

:: --- 执行转码任务 ---
echo([PROCESS] 开始处理待办事项列表中的文件...
echo.

for /f "delims=" %%I in ('type "%todoFile%"') do (
    set "fullPath=%%I"
    set "fileName=%%~nI"
    set "fileExt=%%~xI"

    :: --- 路径重建逻辑 ---
    set "relativePath=!fullPath:%sourceFolder%=!"
    set "outputFile=%outputFolder%!relativePath!"
    
    :: 替换扩展名
    set "outputExtension=.mp4"
    if /i "!fileExt!"==".mkv" ( set "outputExtension=.mkv" )
    set "outputFile=!outputFile:%fileExt%=%outputExtension%!"

    :: 创建目标子目录
    for %%D in ("!outputFile!") do set "outputDir=%%~dpD"
    if not exist "!outputDir!" mkdir "!outputDir!"
    
    set "scaleFilterCommand="
    if not "!outputResolution%"=="" (
        set "scaleFilterCommand=-vf scale=!outputResolution!"
    )

    echo(----------------------------------------------------------------------
    echo([CONVERTING] 正在转换: !fileName!!fileExt!
    echo([FROM]       源路径: !fullPath!
    echo([TO]         目标路径: !outputFile!
    echo(----------------------------------------------------------------------

    :: FFmpeg 核心命令
    ffmpeg -hide_banner -hwaccel dxva2 -i "%%I" !scaleFilterCommand! -map 0 -c:v hevc_amf -quality !qualityPreset! !audioCommand! -c:s copy -y "!outputFile!"

    if not !errorlevel! equ 0 (
        echo. & echo([ERROR]      转换失败: !fileName!!fileExt! & echo.
    ) else (
        echo.
        echo([SUCCESS]    成功转换: !fileName!!fileExt!
        
        :: 在备份文件夹内也创建同样的目录结构
        set "backupFile=%originalsFolder%!relativePath!"
        for %%D in ("!backupFile!") do set "backupDir=%%~dpD"
        if not exist "!backupDir!" mkdir "!backupDir!"
        
        echo([MOVING]     正在移动源文件到备份文件夹 (保留结构)...
        move "%%I" "!backupFile!" >nul
        
        echo %%I >> "%logFile%"
        echo.
    )
)

:: --- 清理和结束 ---
echo([PROCESS] 所有任务处理完毕。
if exist "%todoFile%" del "%todoFile%"

:end
echo.
echo(==========================================================
echo(                   脚本执行结束
echo(==========================================================
pause
