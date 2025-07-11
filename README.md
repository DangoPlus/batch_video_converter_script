# AMD AMF Video Batch Transcoder - README (V14 - Definitive Stable)

## Script Overview
This is a powerful and thoroughly tested Windows Batch script designed to automate video transcoding. This version features a **completely rebuilt core loop logic** that is immune to the variable expansion failures and path errors encountered in previous versions. **This is the definitive, stable build.**

The core design principles of this script are **Safety, Robustness, and Ease of Use.**

## Core Features
*   **Robust Core Logic**: The script uses a direct `FOR /R` loop, the most reliable method for iterating through files, which prevents all previously known bugs.
*   **Handles Complex Filenames**: The path construction logic is fundamentally robust and correctly handles filenames with special characters (`[]()`, spaces, etc.).
*   **Preserves Directory Structure**: Perfectly maintains the original folder structure for both output and backup files.
*   **AMD Hardware Acceleration**: Uses the `hevc_amf` encoder to maximize performance.
*   **Resume Capability**: Automatically logs completed files, so if the script is stopped, it will resume where it left off, skipping already converted files.
*   **Smart File Management**: Moves original files to a structured backup folder upon successful conversion.
*   **Full Stream Preservation**: Copies all subtitle and audio tracks unless configured otherwise.
*   **Highly Configurable**: All important parameters are easily adjusted in the user configuration section.

## First-Time Setup (One Time Only)

You must have **FFmpeg** correctly installed and configured.

#### **Step 1: Download FFmpeg**
1.  Go to the official FFmpeg builds page for Windows: [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
2.  Download the latest "release" build (`ffmpeg-release-full.7z`).

#### **Step 2: Unzip and Set Environment Variable**
1.  Unzip the file to a permanent location, e.g., `C:\ffmpeg`.
2.  Find the `bin` directory inside and copy its full path.
3.  Add this path to your Windows Environment Variables (`Path`).

#### **Step 3: Verify Installation**
1.  Open a new Command Prompt (`cmd.exe`) and type `ffmpeg -version`.
2.  If you see version info, you are ready.

## How to Use

#### **Step 1: Save the Script Correctly (CRITICAL)**
1.  **Delete any old versions** of the script file.
2.  Create a **new, empty text file**.
3.  Copy the code for **V14** into this new file.
4.  Click "File" -> "Save As...".
5.  Set "Save as type" to **"All Files (*.*)"**.
6.  Set "Encoding" to **"ANSI"**.
7.  Name the file `transcode.bat` and save it.

#### **Step 2: Edit Configuration**
Open the `.bat` file with Notepad. At the top, in the `USER CONFIGURATION` section, edit the paths and settings to match your needs.
**Important**: Do not add a trailing backslash (`\`) to your folder paths.

#### **Step 3: Run the Script**
1.  Place your source video files and folders into the `sourceFolder` you defined.
2.  Double-click the `transcode.bat` file to run it.

## Notes
*   **Resetting Progress**: To re-process all files, simply delete the `completed_list.log` file from the script's directory.
*   **Backups**: Periodically check your `originalsFolder`. Once you confirm the transcoded videos are correct, you can safely delete the backed-up originals to save space.

## Disclaimer
Always test this script with a few non-critical files first to ensure it behaves as you expect. The author is not responsible for any potential data loss. Use at your own risk and always have backups of important files.

# AMD AMF 视频批量转码脚本 - 使用说明 (V10 - 最终版)

## 脚本简介
这是一个功能强大且经过充分测试的 Windows 批处理脚本，旨在自动化视频转码流程。它利用 FFmpeg 和您的 AMD 显卡（通过 AMF 硬件加速）来高效地将大量视频文件转换为高质量、小体积的 H.265 (HEVC) 编码格式。

这个脚本的核心设计理念是 **安全、健壮、易用**。

## 核心功能
*   **保留目录结构**: 在输出和备份时，**完整保留**原始文件的文件夹结构，绝不破坏。
*   **AMD 硬件加速**: 使用 `hevc_amf` 编码器，充分利用您的 AMD 显卡性能，大幅提升转码速度。
*   **断点续传**: 自动记录已成功转换的文件。如果脚本中途停止，下次运行时会自动从上次中断的地方继续，不会重复工作。
*   **智能文件管理**: 成功转换后，原始文件会自动移动到备份文件夹（并保留目录结构），方便您检查后统一删除。
*   **完整流保留**:
    *   **字幕**: 完美复制所有内嵌的字幕轨道，无任何丢失。
    *   **多音轨**: 完美复制所有音频轨道。
*   **高度可配置**: 无需修改核心代码，只需在脚本顶部的配置区即可轻松调整所有重要参数。
*   **健壮的兼容性**: 解决了在不同系统环境下可能出现的编码乱码和命令语法错误问题。

## ★★ 重要提示：关于编码问题 ★★
为了确保脚本中的中文提示能正确显示，并且脚本本身能被 Windows 命令解释器正确识别，请务必遵守以下操作：
1.  用 Windows **记事本** 打开 `.bat` 脚本文件。
2.  点击“文件” -> “另存为”。
3.  在弹出的窗口底部，将“**编码**”从 `UTF-8` 修改为 **`ANSI`**。
4.  保存并覆盖原文件。之后即可正常运行。

## 首次使用设置 (只需一次)

在使用脚本前，您必须正确安装和配置 **FFmpeg**。

#### **步骤 1: 下载 FFmpeg**
1.  前往 FFmpeg 的官方 Windows 构建页面: [https://www.gyan.dev/ffmpeg/builds/](https://www.gyan.dev/ffmpeg/builds/)
2.  找到最新的 "release builds" 部分，下载名为 `ffmpeg-release-full.7z` 的文件。

#### **步骤 2: 解压并配置环境变量**
1.  将下载的 `.7z` 文件解压到一个**固定不动的位置**。例如，`C:\ffmpeg`。
2.  进入解压后的文件夹，找到 `bin` 文件夹。此文件夹的完整路径就是我们需要的，例如: `C:\ffmpeg\ffmpeg-7.0-full_build\bin`。
3.  **将此 `bin` 文件夹路径添加到 Windows 的环境变量中**:
    *   右键点击 “此电脑” -> “属性” -> “高级系统设置” -> “环境变量”。
    *   在 “系统变量” 框中，找到并双击 `Path` 变量。
    *   点击 “新建”，然后将您刚才复制的 `bin` 文件夹完整路径粘贴进去，并一路点击“确定”保存。

#### **步骤 3: 验证安装**
1.  按 `Win + R`，输入 `cmd` 并回车，打开一个新的命令提示符窗口。
2.  输入 `ffmpeg -version` 并按回车。
3.  如果您看到关于 FFmpeg 版本的信息，说明安装配置成功！

## 如何使用

#### **步骤 1: 修改配置**
用记事本或任何文本编辑器打开 `.bat` 文件。找到顶部的 **`用户配置区域`**，根据您的需求修改路径、质量、分辨率和音频选项。

**重要**: 文件夹路径末尾**请勿**添加 `\`。脚本有自动净化功能，但保持良好习惯更好。

#### **步骤 2: 运行脚本**
1.  将您要转换的视频文件或文件夹放入您设置的 `sourceFolder` 中。
2.  双击运行 `.bat` 文件。
3.  一个命令提示符窗口将会出现，并开始自动处理文件。您可以随时关闭窗口来暂停任务。

## 注意事项
*   **重置进度**: 如果您想让脚本重新转换所有文件（例如您更改了配置参数），只需**删除脚本目录下的 `completed_list.log` 文件**即可。
*   **备份**: 强烈建议定期检查 `originalsFolder` 中的备份文件。在确认转码后的视频没有问题后，您可以安全地手动删除这些备份文件以释放磁盘空间。

## 免责声明
*   请务必先用几个不重要的测试文件来运行此脚本，以确保它的行为符合您的预期。
*   对于因使用此脚本可能造成的任何数据丢失，作者不承担任何责任。请自行做好重要文件的备份工作。
