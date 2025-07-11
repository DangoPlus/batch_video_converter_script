# 项目：跨平台视频转码GUI - 下一步开发计划 (Next Step Plan)

本文档旨在为基于 **Electron** 和 **FFmpeg** 的跨平台视频转码工具提供一个清晰、分步的开发路线图。

## 1. 核心目标 (Core Objectives)

*   **GUI化**: 将现有命令行逻辑封装进一个直观、易用的图形用户界面。
*   **跨平台**: 确保应用能无缝运行于 Windows, macOS, 和 Linux。
*   **自洽与便携**: 将 FFmpeg 完全打包进应用，实现“开箱即用”，无需用户安装任何外部依赖。
*   **智能化**: 自动检测可用的硬件加速方案，并提供给用户选择，同时支持纯CPU软件编码作为备用方案。
*   **用户友好**: 提供清晰的进度反馈、错误提示和文件管理功能。

---

## 2. 技术选型 (Technology Stack)

*   **应用框架**: **Electron** - 用于构建跨平台桌面应用。
*   **界面技术**: **HTML / CSS / JavaScript** (可选用 `Vue` 或 `React` 等框架以简化开发)。
*   **核心引擎**: **FFmpeg** - 用于执行所有的音视频处理任务。
*   **后端逻辑**: **Node.js** (Electron自带) - 用于文件操作和调用FFmpeg进程。
*   **打包工具**: **Electron Builder** - 用于将应用打包成各平台的安装文件。

---

## 3. 开发阶段与步骤 (Development Phases & Steps)

### 阶段一：项目基础架构搭建 (Phase 1: Project Scaffolding)

1.  **初始化Electron项目**:
    *   使用 `npm init` 或 `yarn init` 创建 `package.json`。
    *   安装 `electron` 和 `electron-builder` 作为开发依赖。
    *   创建基础的项目结构：
        ```
        your-app/
        ├── extraResources/
        │   ├── win/
        │   ├── mac/
        │   └── linux/
        ├── src/
        │   ├── main/       # 主进程代码
        │   │   ├── main.js
        │   │   └── preload.js
        │   ├── renderer/   # 渲染进程代码 (UI)
        │   │   ├── index.html
        │   │   ├── renderer.js
        │   │   └── style.css
        └── package.json
        ```

2.  **集成FFmpeg二进制文件**:
    *   下载 Windows (`.exe`), macOS (universal), Linux (x86_64) 版本的 `ffmpeg` 和 `ffprobe`。
    *   将它们分别放入 `extraResources` 下对应的 `win`, `mac`, `linux` 文件夹中。
    *   **重要**: 在 macOS/Linux 系统上，为 `ffmpeg` 和 `ffprobe` 文件添加可执行权限 (`chmod +x ffmpeg`)。

3.  **配置 `package.json`**:
    *   设置 `main` 入口指向 `src/main/main.js`。
    *   添加 `build` 配置，并设置 `extraResources` 规则，确保FFmpeg文件能被正确打包。

### 阶段二：核心功能实现 (Phase 2: Core Functionality)

1.  **实现跨平台二进制文件定位器**:
    *   在 `main.js` 中，编写 `getFFmpegPath()` 和 `getFFprobePath()` 函数。
    *   这两个函数需要能根据 `process.platform` ('win32', 'darwin', 'linux') 和 `app.isPackaged` 状态，智能地返回正确的 `ffmpeg` 和 `ffprobe` 路径。

2.  **实现智能硬件加速方案检测 (★ 关键创新点)**
    *   在 `main.js` 中创建一个名为 `detectHardwareAccel()` 的异步函数。此函数在应用启动或用户点击“刷新”按钮时调用。
    *   **检测逻辑**:
        a. **基础方案**: 首先添加“**软件编码 (libx265 - CPU)**”作为必定可用的基础选项。
        b. **Windows检测**:
           *   检查 `process.platform === 'win32'`。
           *   执行 `ffmpeg.exe -hide_banner -encoders | findstr hevc_amf` 命令。如果命令成功且有输出，则“**AMD AMF (硬件)**”可用。
           *   执行 `ffmpeg.exe -hide_banner -encoders | findstr hevc_nvenc` 命令。如果成功，则“**NVIDIA NVENC (硬件)**”可用。
           *   执行 `ffmpeg.exe -hide_banner -encoders | findstr hevc_qsv` 命令。如果成功，则“**Intel QuickSync (硬件)**”可用。
        c. **macOS检测**:
           *   检查 `process.platform === 'darwin'`。
           *   执行 `ffmpeg -hide_banner -encoders | grep hevc_videotoolbox`。如果成功，则“**Apple VideoToolbox (硬件)**”可用。
        d. **Linux检测**:
           *   检查 `process.platform === 'linux'`。
           *   执行 `ffmpeg -hide_banner -encoders | grep hevc_vaapi`。如果成功，则“**VA-API (Intel/AMD硬件)**”可用。
    *   **实现方式**: 使用 `Node.js` 的 `child_process.exec` 来执行上述检测命令，并根据命令的退出码和输出来判断可用性。
    *   **通信**: `detectHardwareAccel` 函数将最终检测到的可用方案列表（例如 `['软件编码', 'AMD AMF']`）通过 `ipcMain` 发送给渲染进程。

3.  **实现主进程与渲染进程的通信 (IPC)**:
    *   **定义通道**: 规划好用于通信的IPC通道，例如：
        *   `'get-hw-accels'`: 渲染进程请求获取可用硬件加速列表。
        *   `'hw-accels-result'`: 主进程返回检测结果。
        *   `'start-transcode'`: 渲染进程发送转码任务和所有配置。
        *   `'ffmpeg-output'`: 主进程实时转发FFmpeg的日志和进度。
        *   `'transcode-complete'`: 主进程通知转码成功。
        *   `'transcode-error'`: 主进程通知转码失败。
    *   **使用`preload.js`**: 通过 `contextBridge` 安全地将 `ipcRenderer` 的功能暴露给渲染进程，这是目前推荐的最佳实践。

4.  **实现FFmpeg调用逻辑**:
    *   在主进程中，编写监听 `'start-transcode'` 的函数。
    *   该函数接收来自界面的配置，根据用户选择的硬件加速方案，动态构建 `ffmpeg` 的参数数组。
    *   使用 `child_process.spawn` 启动 `ffmpeg` 进程，因为它适合长时任务并能实时捕获输出流。
    *   监听 `spawn` 进程的 `stdout` 和 `stderr` 流，并将数据实时通过 `'ffmpeg-output'` 通道发送回界面。
    *   监听 `close` 和 `error` 事件，以判断任务最终状态，并通过相应通道通知界面。

### 阶段三：用户界面(UI)开发 (Phase 3: User Interface)

1.  **布局设计**:
    *   **输入区**: "选择源文件/文件夹"按钮、已选路径显示框。
    *   **输出区**: "设置输出目录"按钮、已选路径显示框。
    *   **配置区**:
        *   **视频**:
            *   硬件加速方案下拉菜单 (由主进程检测结果动态填充)。
            *   编码模式单选框 (“质量优先” vs “体积优先”)。
            *   质量/码率设置输入框 (根据模式动态显示/隐藏)。
            *   分辨率设置输入框。
        *   **音频**: 音频处理方式单选框 (“直接复制” vs “压缩AAC”)。
    *   **控制区**: “开始转换”按钮、"停止"按钮、进度条。
    *   **反馈区**: 一个大的只读文本域，用于实时显示FFmpeg的日志输出。

2.  **交互实现 (`renderer.js`)**:
    *   应用启动时，立即向主进程发送 `'get-hw-accels'` 请求，并在收到结果后动态填充下拉菜单。
    *   为所有按钮和输入控件绑定事件监听器。
    *   实现配置区控件之间的联动逻辑（例如，选择“体积优先”时，显示码率输入框）。
    *   “开始转换”按钮点击后，收集所有界面配置，组装成一个配置对象，通过 `'start-transcode'` 发送给主进程。
    *   监听 `'ffmpeg-output'`，将收到的数据显示在日志区，并根据日志内容解析进度更新进度条。
    *   根据 `'transcode-complete'` 和 `'transcode-error'` 事件，向用户显示最终的成功或失败提示。

### 阶段四：打包与分发 (Phase 4: Packaging & Distribution)

1.  **最终测试**: 在 Windows, macOS, Linux 虚拟机或实体机上，对开发完成的应用进行完整的功能测试。
2.  **图标设计**: 为应用设计一个 `.ico` (Windows) 和 `.icns` (macOS) 图标。
3.  **打包命令**:
    *   在 `package.json` 的 `scripts` 中添加打包命令：
        ```json
        "scripts": {
          "dist:win": "electron-builder --win",
          "dist:mac": "electron-builder --mac",
          "dist:linux": "electron-builder --linux"
        }
        ```
    *   在对应的操作系统上运行打包命令（例如，在Windows上运行 `npm run dist:win`）。
4.  **生成安装包**: `electron-builder` 会在 `dist/` 目录下生成对应平台的安装包（`.exe`, `.dmg`, `.AppImage`）。
5.  **编写README**: 撰写一份清晰的用户手册，说明软件功能和使用方法。

---

通过遵循这份计划，您将能够系统性地、有条不紊地构建出一个功能强大、用户友好且真正跨平台的视频转码工具。祝您开发顺利！
