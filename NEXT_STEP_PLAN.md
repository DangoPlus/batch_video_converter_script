# 项目：跨平台视频转码GUI - 完整开发计划

**版本**: 1.0 (最终版)
**目标**: 构建一个功能完整、用户友好、可跨平台运行且拥有自动化构建流程的视频转码工具。

---

## 目录
1.  [核心目标与原则](#1-核心目标与原则)
2.  [技术选型](#2-技术选型)
3.  [开发阶段与详细步骤](#3-开发阶段与详细步骤)
    *   [阶段一：项目基础架构搭建](#阶段一项目基础架构搭建)
    *   [阶段二：核心后端功能实现](#阶段二核心后端功能实现)
    *   [阶段三：用户界面(UI)开发](#阶段三用户界面ui开发)
    *   [阶段四：自动化构建与部署(CI/CD)](#阶段四自动化构建与部署cicd)
4.  [最终测试与发布流程](#4-最终测试与发布流程)

---

## 1. 核心目标与原则

*   **GUI化**: 将所有功能通过直观、易用的图形用户界面提供，彻底取代命令行操作。
*   **跨平台**: 应用必须能无缝运行于主流的三大桌面操作系统：Windows, macOS, 和 Linux。
*   **自洽与便携 (Self-Contained & Portable)**: 应用需打包所有必要的依赖（尤其是FFmpeg），实现“开箱即用”，用户无需安装任何外部环境。
*   **智能化**:
    *   **自动检测硬件加速**: 应用能自动检测当前系统支持的硬件加速方案，并以列表形式供用户选择。
    *   **提供备用方案**: 必须包含纯CPU软件编码（如 `libx265`）作为最可靠的备用选项。
*   **用户友好**: 提供清晰的实时进度反馈（日志和进度条）、明确的错误提示、完善的文件管理功能，以及简洁的交互设计。
*   **自动化 (Automation)**: 利用CI/CD流程（GitHub Actions）实现云端自动化测试和打包，确保构建过程的一致性、可靠性，并简化发布流程。

## 2. 技术选型

*   **应用框架**: **Electron** - 用于构建跨平台桌面应用的核心框架。
*   **界面技术**: **HTML / CSS / JavaScript**。推荐使用现代前端框架（如 **Vue.js** 或 **React**）来构建可维护、响应式的用户界面。
*   **核心引擎**: **FFmpeg** - 用于执行所有的音视频处理任务。
*   **后端逻辑**: **Node.js** (由Electron内置提供) - 用于文件系统操作、进程管理和调用FFmpeg。
*   **打包工具**: **Electron Builder** - 用于将应用打包成各平台的原生安装文件（`.exe`, `.dmg`, `.AppImage`等）。
*   **持续集成/持续部署 (CI/CD)**: **GitHub Actions** - 用于自动化构建、测试和发布流程。

---

## 3. 开发阶段与详细步骤

### 阶段一：项目基础架构搭建

1.  **初始化Electron项目**:
    *   使用 `npm init` 或 `yarn init` 创建 `package.json`。
    *   安装开发依赖: `npm install --save-dev electron electron-builder`。
    *   创建清晰、规范的项目结构：
        ```
        your-transcoder-app/
        ├── .github/
        │   └── workflows/
        │       └── build-app.yml  # CI/CD 配置文件，在此阶段创建空文件
        ├── .gitignore             # 忽略 node_modules, dist, local_dev_bin 等
        ├── src/
        │   ├── main/              # 主进程 (后端)
        │   │   ├── main.js        # 应用主入口
        │   │   └── preload.js     # 安全的IPC通信桥梁
        │   ├── renderer/          # 渲染进程 (UI)
        │   │   ├── index.html
        │   │   ├── renderer.js
        │   │   └── style.css
        └── package.json
        ```

2.  **配置 `package.json`**:
    *   设置 `main` 入口指向 `src/main/main.js`。
    *   添加运行和打包脚本：
        ```json
        "scripts": {
          "start": "electron .",
          "dist": "electron-builder",
          "dist:win": "electron-builder --win",
          "dist:mac": "electron-builder --mac",
          "dist:linux": "electron-builder --linux"
        }
        ```
    *   添加 `build` 配置，并**预先定义** `extraResources` 规则，即使该目录尚不存在：
        ```json
        "build": {
          "appId": "com.yourcompany.your-transcoder",
          "productName": "我的超级转码器",
          "files": ["src/main/", "src/renderer/", "package.json"],
          "extraResources": [{
            "from": "./extraResources/",
            "to": "extraResources",
            "filter": ["**/*"]
          }],
          "win": { "target": "nsis", "icon": "build/icon.ico" },
          "mac": { "target": "dmg", "icon": "build/icon.icns" },
          "linux": { "target": "AppImage", "icon": "build/icon.png" }
        }
        ```

3.  **本地开发环境准备 (可选，为方便调试)**:
    *   在项目根目录创建一个 `local_dev_bin/` 文件夹。
    *   手动下载一个对应您当前开发系统（如Windows）的FFmpeg版本，并将其 `ffmpeg.exe` 和 `ffprobe.exe` 放入此文件夹。
    *   将 `local_dev_bin/` 添加到项目根目录的 `.gitignore` 文件中，**严禁**将二进制文件提交到Git仓库。

### 阶段二：核心后端功能实现

1.  **实现跨平台二进制文件定位器 (`main.js`)**:
    *   编写 `getFFmpegPath()` 和 `getFFprobePath()` 函数。
    *   这两个函数必须能智能地处理三种情况：
        1.  **本地开发**: 如果 `app.isPackaged` 为 `false`，则返回指向 `local_dev_bin/` 目录的路径。
        2.  **生产环境 (打包后)**: 如果 `app.isPackaged` 为 `true`，则根据 `process.platform` ('win32', 'darwin', 'linux') 返回指向 `process.resourcesPath/extraResources/[platform]/` 的路径。
        3.  **平台兼容**: 根据不同平台，文件名应正确处理（Windows下为 `.exe` 后缀）。

2.  **实现智能硬件加速方案检测 (`main.js`)**:
    *   创建一个名为 `detectHardwareAccel()` 的异步函数，在应用启动时自动调用。
    *   **检测逻辑**:
        a. **基础方案**: 无条件地将 “**软件编码 (libx265 - CPU)**” 添加到可用方案列表。
        b. **平台相关检测**:
           *   **Windows**: 依次执行 `ffmpeg.exe -hide_banner -encoders` 命令，并用 `findstr` 检查是否包含 `hevc_amf`, `hevc_nvenc`, `hevc_qsv`，以确定AMD/NVIDIA/Intel硬件加速的可用性。
           *   **macOS**: 执行 `ffmpeg -hide_banner -encoders | grep hevc_videotoolbox` 来检测 `Apple VideoToolbox`。
           *   **Linux**: 执行 `ffmpeg -hide_banner -encoders | grep hevc_vaapi` 来检测 `VA-API`。
    *   **实现方式**: 使用Node.js的 `child_process.exec` 执行检测命令，并根据其退出码和输出来判断。
    *   **通信**: 函数将最终检测到的可用方案列表（如 `['软件编码 (CPU)', 'AMD AMF (硬件)']`）缓存起来，并通过IPC通道发送给渲染进程。

3.  **实现主进程与渲染进程的IPC通信 (`preload.js` & `main.js`)**:
    *   **定义通道**: 规划好所有通信通道，如 `get-hw-accels`, `start-transcode`, `ffmpeg-output`, `transcode-complete`, `transcode-error`。
    *   **安全暴露**: 使用 `preload.js` 中的 `contextBridge`，安全地将 `ipcRenderer.send` 和 `ipcRenderer.on` 的功能封装后暴露给渲染进程，避免直接暴露 `require('electron')`。

4.  **实现FFmpeg调用逻辑 (`main.js`)**:
    *   在主进程中，编写监听 `'start-transcode'` 的函数，该函数接收来自UI的所有配置参数。
    *   根据用户选择的硬件加速方案，**动态构建**一个完整的 `ffmpeg` 参数数组。
    *   使用 `child_process.spawn` 启动 `ffmpeg` 进程，实时监听其 `stdout` 和 `stderr` 流，并将数据通过 `'ffmpeg-output'` 通道转发给UI。
    *   监听 `close` 和 `error` 事件，以判断任务最终状态，并通知UI。

### 阶段三：用户界面(UI)开发

1.  **布局设计 (`index.html` & `style.css`)**:
    *   **输入区**: "选择源文件/文件夹" 按钮、已选路径显示。
    *   **输出区**: "设置输出目录" 按钮、已选路径显示。
    *   **配置区**:
        *   **视频**: 硬件加速方案下拉菜单（内容由后端动态生成）、编码模式单选框、质量/码率设置、分辨率设置。
        *   **音频**: 音频处理方式单选框。
    *   **控制区**: “开始转换”、“停止任务”按钮、显示进度的进度条。
    *   **反馈区**: 一个大的只读文本区域，用于实时显示FFmpeg日志。

2.  **交互实现 (`renderer.js`)**:
    *   应用加载后，立即向主进程请求可用的硬件加速方案列表，并动态填充下拉菜单。
    *   为所有UI控件绑定事件监听器，实现界面上的联动逻辑。
    *   “开始转换”按钮负责收集所有界面配置，组装成配置对象，发送给主进程。
    *   实时监听主进程转发的FFmpeg日志，显示在日志区，并根据日志内容解析进度（如 `frame=...` 或 `time=...`）来更新进度条。
    *   根据转码完成或失败的信号，向用户显示清晰、友好的弹窗或状态提示。

### 阶段四：自动化构建与部署(CI/CD)

1.  **创建GitHub Actions工作流 (`.github/workflows/build-app.yml`)**:
    *   **触发条件**: 配置工作流在代码推送到 `main` 分支时自动触发。
    *   **矩阵构建 (Matrix Strategy)**: 设置 `strategy.matrix.os` 以并行在 `windows-latest`, `macos-latest`, `ubuntu-latest` 三个云端服务器上执行任务。

2.  **工作流核心步骤**:
    a. **环境准备**: 检出代码、设置Node.js环境、安装npm依赖。
    b. **动态获取FFmpeg**:
       *   **定义源**: 选择一个可靠的FFmpeg构建来源（如 **BtbN/FFmpeg-Builds**）。
       *   **脚本化下载**: 在工作流中添加一个`shell`脚本步骤。该脚本通过 `runner.os` 变量判断当前系统，下载对应的FFmpeg压缩包。
       *   **放置与授权**: 脚本负责在云端服务器上创建`extraResources/[platform]`目录，解压并将`ffmpeg`/`ffprobe`文件移动到此目录，并在macOS/Linux上为其添加可执行权限(`chmod +x`)。
    c. **执行打包**: 在FFmpeg准备就绪后，运行 `npm run dist` 命令。`electron-builder`将自动打包与当前Runner操作系统匹配的应用。
    d. **上传构建产物 (Artifacts)**: 使用`actions/upload-artifact`将`dist/`目录下生成的安装包上传。

---

## 4. 最终测试与发布流程

1.  **下载产物**: 从每次成功的GitHub Actions运行结果中，下载所有平台的安装包。
2.  **全面测试**: 在干净的Windows, macOS, Linux环境（虚拟机或物理机）中，对下载的安装包进行全面的功能和用户体验测试。
3.  **创建发布 (Release)**:
    *   在GitHub仓库中创建一个新的Tag和Release。
    *   将所有平台的安装包作为附件上传到该Release。
    *   撰写详细的更新日志（Release Notes），说明此版本的新功能、修复的Bug和已知问题。
    *   分享Release链接给用户。

通过遵循这份详尽的计划，您将能够系统性地、有条不紊地将一个想法，转变为一个功能强大、用户友好、工程上可靠且可维护的跨平台软件产品。
