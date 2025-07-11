@echo off
setlocal enabledelayedexpansion

:: =================================================================================
:: AMD 硬件加速转码脚本 (FFmpeg & AMF)
:: 功能:
:: 1. 自动扫描指定文件夹的视频文件。
:: 2. 使用 AMD AMF 硬件加速 (HEVC/H.265) 进行转码。
:: 3. 记录已完成列表，支持任务中断后继续。
:: 4. 源文件为 MKV 则输出 MKV，否则输出 MP4。
:: 5. 成功后将源文件移动到备份文件夹。
:: =================================================================================

echo.
echo ==========================================================
echo               AMD AMF 视频批量转码脚本
echo ==========================================================
echo.

:: --- 1. 用户配置区域 ---
:: 请根据您的实际情况修改以下路径。文件夹路径末尾不要带"\"。
SET "sourceFolder=D:\Videos\ToConvert"
SET "outputFolder=D:\Videos\Converted"
SET "originalsFolder=D:\Videos\Original_Files_Backup"

:: --- 2. 脚本变量设置 ---
:: 日志文件，用于记录已处理的文件，实现断点续传
SET "logFile=%~dp0completed_list.log"
:: 临时待办事项列表
SET "todoFile=%~dp0todo_list.tmp"

:: --- 3. 环境检查与准备 ---
echo [INFO] 检查 FFmpeg 环境...
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 未在系统路径中找到 ffmpeg.exe。
    echo [ERROR] 请确保您已正确安装 FFmpeg 并将其添加到系统环境变量 Path 中。
    pause
    exit /b
)
echo [SUCCESS] FFmpeg 环境正常。

echo.
echo [INFO] 源文件目录: %sourceFolder%
echo [INFO] 输出文件目录: %outputFolder%
echo [INFO] 源文件备份目录: %originalsFolder%
echo.

:: 如果输出或备份文件夹不存在，则自动创建
if not exist "%outputFolder%" (
    echo [INFO] 输出文件夹不存在，正在创建: %outputFolder%
    mkdir "%outputFolder%"
)
if not exist "%originalsFolder%" (
    echo [INFO] 源文件备份文件夹不存在，正在创建: %originalsFolder%
    mkdir "%originalsFolder%"
)
:: 如果日志文件不存在，则创建
if not exist "%logFile%" (
    echo [INFO] 首次运行，正在创建日志文件: %logFile%
    type nul > "%logFile%"
)

:: --- 4. 生成待办事项列表 ---
echo [PROCESS] 正在扫描源文件夹并生成待办事项列表...
if exist "%todoFile%" del "%todoFile%"

:: 递归扫描指定类型的视频文件
for /r "%sourceFolder%" %%F in (*.mkv, *.mp4, *.mov, *.avi, *.flv, *.webm) do (
    :: 检查该文件是否已经被记录在完成日志中
    findstr /L /X /C:"%%F" "%logFile%" >nul
    :: 如果 findstr 出错 (即没找到)，说明是未处理的新文件
    if !errorlevel! equ 1 (
        echo %%F >> "%todoFile%"
    )
)

if not exist "%todoFile%" (
    echo [COMPLETE] 没有找到需要转换的新文件。所有任务已完成。
    goto :end
)

:: --- 5. 执行转码任务 ---
echo [PROCESS] 开始处理待办事项列表中的文件...
echo.

:: 逐行读取待办事项列表进行处理
for /f "delims=" %%I in ('type "%todoFile%"') do (
    
    :: 提取文件名和扩展名
    set "fullPath=%%I"
    set "fileName=%%~nI"
    set "fileExt=%%~xI"

    :: 判断输出格式
    set "outputExtension=.mp4"
    if /i "!fileExt!"==".mkv" (
        set "outputExtension=.mkv"
    )

    set "outputFile=%outputFolder%\!fileName!!outputExtension!"

    echo ----------------------------------------------------------------------
    echo [CONVERTING] 正在转换: !fileName!!fileExt!
    echo [OUTPUT]     输出路径: !outputFile!
    echo ----------------------------------------------------------------------

    :: =========================================================================
    :: FFmpeg 核心命令
    :: -hwaccel dxva2          : 开启DXVA2硬件解码 (自动模式也可，但指定更可靠)
    :: -i "%%I"                : 输入文件
    :: -c:v hevc_amf           : 使用AMD AMF硬件编码器，HEVC(H.265)格式，效率最高
    :: -quality balanced       : 质量预设，"balanced"是质量和速度的良好平衡
    :: -c:a copy               : 直接复制音频流，不重新编码，速度快且无损音质
    :: -y                      : 如果输出文件已存在，则覆盖
    :: =========================================================================
    ffmpeg -hide_banner -hwaccel dxva2 -i "%%I" -c:v hevc_amf -quality balanced -c:a copy -y "!outputFile!"

    :: 检查 FFmpeg 是否成功执行 (errorlevel为0表示成功)
    if not !errorlevel! equ 0 (
        echo.
        echo [ERROR]      转换失败: !fileName!!fileExt!
        echo.
    ) else (
        echo.
        echo [SUCCESS]    成功转换: !fileName!!fileExt!
        
        :: 转换成功后，将源文件移动到备份文件夹
        echo [MOVING]     正在移动源文件到: %originalsFolder%
        move "%%I" "%originalsFolder%\" >nul
        
        :: 将处理完成的文件完整路径记录到日志文件中
        echo %%I >> "%logFile%"
        echo.
    )
)

:: --- 6. 清理和结束 ---
echo [PROCESS] 所有任务处理完毕。
if exist "%todoFile%" del "%todoFile%"

:end
echo.
echo ==========================================================
echo                    脚本执行结束
echo ==========================================================
pause
