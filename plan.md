# Alpine Linux Raspberry Pi 2B HP LaserJet 1020 打印服务器方案

## 一、项目目标

创建一个可重复构建的 GitHub 仓库，输出适用于 Raspberry Pi 2B 的 Alpine Linux SD 卡镜像，具备以下功能：

* 使用 `armv7` 架构启动 Raspberry Pi 2B。
* USB 连接 HP LaserJet 1020。
* 集成 CUPS、Ghostscript、cups-filters 和 foo2zjs。
* 打印机每次重新通电或重新插入 USB 后，自动上传 `sihp1020.dl` 固件。
* 自动创建 HP LaserJet 1020 CUPS 队列。
* 通过局域网提供 IPP/CUPS 打印服务。
* 可选通过 Avahi 发布 `hp1020.local` 和 IPP 服务。
* 默认启用 Dropbear SSH，允许 root 使用初始密码 `1234` 登录。
* GitHub Actions 自动编译驱动、生成系统镜像、校验并上传构建产物。
* 不在公开 Git 仓库中直接提交来源和授权不明确的 HP 固件文件。

基础镜像构建器选择 `raspi-alpine/builder`。该项目支持将自定义脚本放入构建阶段，能生成完整 SD 卡镜像和更新镜像，并明确支持 Raspberry Pi 2 使用 `armv7`。

---

## 二、需要使用的 GitHub 仓库

### 1. Raspberry Pi Alpine 镜像构建器

```text
https://github.com/raspi-alpine/builder.git
```

用途：

* 创建 Raspberry Pi 可启动分区。
* 安装 Alpine rootfs。
* 安装 Raspberry Pi 内核、固件和 U-Boot。
* 执行项目自定义的 Stage 60 脚本。
* 输出 `sdcard.img.gz`、`sdcard_update.img.gz` 和 SHA-256 文件。

仓库默认分支：

```text
master
```

Codex 应在 `config/sources.lock` 中固定具体 commit SHA，不要长期直接跟随浮动的 `master`。

该构建器采用阶段化设计，Stage 60 专门用于用户自定义脚本，Stage 70 会裁剪内核模块，因此必须明确保留 USB 打印机需要的 `usblp` 模块。

### 2. HP 1020 的 foo2zjs 驱动

```text
https://github.com/OpenPrinting/foo2zjs.git
```

用途：

* 编译 `foo2zjs` 转换程序。
* 安装 HP LaserJet 1020 对应的 PPD、Foomatic 数据和 CUPS 过滤器。
* 提供 `getweb 1020` 固件获取逻辑。
* 提供 HP 1020 固件热插拔加载逻辑作为移植参考。

仓库默认分支：

```text
main-fixes
```

该仓库明确列出了 HP LaserJet 1020 支持，并提供 `getweb 1020`、驱动安装和热插拔安装步骤。

### 3. Raspberry Pi 官方固件仓库

```text
https://github.com/raspberrypi/firmware.git
```

通常不需要项目 Workflow 手动完整 clone，因为 `raspi-alpine/builder` 会按照 `RPI_FIRMWARE_GIT` 配置获取所需内容。

为了可重复构建，Codex 应：

* 固定 `RPI_FIRMWARE_BRANCH`。
* 记录最终使用的 firmware commit。
* 不要在每次构建时无条件 clone 完整历史。
* 优先使用构建器自带的 firmware 获取和缓存机制。

### 4. 不需要手动 clone 的 GitHub Actions 组件

Workflow 可以使用以下 Actions，但应固定到明确的 major 版本或 commit SHA：

* `actions/checkout`
* `docker/setup-qemu-action`
* `docker/setup-buildx-action`
* `actions/cache`
* `actions/upload-artifact`

---

## 三、目标平台参数

第一版固定为：

| 参数        | 值                 |
| --------- | ----------------- |
| 硬件        | Raspberry Pi 2B   |
| 架构        | `armv7`           |
| Alpine 分支 | 首选 `v3.23`        |
| 设备管理器     | `eudev`           |
| Init      | OpenRC            |
| 打印服务      | CUPS              |
| 网络发现      | Avahi，可配置关闭       |
| USB 打印模块  | `usblp`           |
| 根文件系统     | 只读 A/B rootfs     |
| 持久数据      | builder 的 data 分区 |
| 远程管理      | Dropbear SSH       |
| 初始账户      | `root` / `1234`    |

不能使用构建器默认的 `aarch64`，因为 Raspberry Pi 2B 的本项目目标应设置为 `ARCH=armv7`。构建器文档显示 Pi 2 同时支持 armhf 和 armv7，而默认架构已经是 aarch64。

Alpine 当前分支提供 CUPS、cups-filters、Ghostscript、Avahi 等组件；Ghostscript 是体积最大的依赖之一，因此构建时应避免安装文档、开发包和调试包。

---

## 四、总体构建路线

### 阶段 1：准备构建环境

GitHub Actions 使用 Ubuntu x86_64 Runner。

Workflow 应完成：

1. Checkout 自定义项目。
2. Clone 并固定 `raspi-alpine/builder`。
3. Clone 并固定 `OpenPrinting/foo2zjs`。
4. 启用 QEMU/binfmt 的 `linux/arm/v7` 支持。
5. 初始化 Docker Buildx。
6. 恢复 APK、源码和 builder 缓存。

不建议直接依赖浮动的 `ghcr.io/raspi-alpine/builder:latest`。第一版可以使用，但正式方案应从已固定 commit 的 builder 源码构建本地 Docker 镜像。

### 阶段 2：构建 foo2zjs APK

在 `linux/arm/v7` Alpine 构建环境中：

1. 安装 `alpine-sdk`、CUPS 开发依赖和编译工具。
2. 使用项目中的 `packages/foo2zjs/APKBUILD` 构建 APK。
3. 从已固定 commit 的 `OpenPrinting/foo2zjs` 获取源码。
4. 将包拆分为：

   * `foo2zjs`
   * `foo2zjs-cups`
   * `foo2zjs-hp1020`
   * 可选的 `foo2zjs-doc`
5. 默认镜像只安装前三个运行包。
6. 将 APK 放入本地签名仓库。
7. 生成 APKINDEX。
8. 将本地仓库传递给镜像构建阶段。

不建议直接在最终 rootfs 中运行 `make install`。制作 APK 更容易追踪文件、卸载、升级和重现构建结果。

### 阶段 3：获取 HP 1020 固件

构建过程调用 foo2zjs 的固件获取机制生成：

```text
sihp1020.dl
```

建议支持两种模式：

* **公开仓库模式**：Workflow 构建时下载固件并验证 SHA-256。
* **私有构建模式**：从 GitHub Actions Secret、私有 Release Asset 或私有存储中读取固件。

不得默认把固件二进制提交进公开 Git 仓库。

最终公开 Release 是否包含该固件，需要单独确认再分发许可。个人使用的 Workflow Artifact 可以设置较短保留时间。

### 阶段 4：组装 Alpine rootfs

通过 builder 的自定义 Stage 60 完成：

1. 配置 Alpine main 和 community 仓库。
2. 添加项目本地 APK 仓库和公钥。
3. 安装：

   * `cups`
   * `cups-openrc`
   * `cups-filters`
   * `ghostscript`
   * `dbus`
   * `dbus-openrc`
   * `avahi`
   * `avahi-openrc`
   * `eudev`
   * `eudev-openrc`
   * `usbutils`
   * 自编译的 foo2zjs 包
4. 保留 `usblp` 内核模块。
5. 配置 OpenRC 服务。
6. 写入 CUPS、Avahi、udev 和首次启动配置。
7. 设置主机名，例如 `hp1020`.
8. 默认通过 DHCP 获取地址。
9. 启用 Dropbear SSH，将 builder 默认的 `root/alpine` 改为 `root/1234`，允许首次远程登录；同时支持可选注入 SSH 公钥。

固定初始密码只用于受信任的隔离内网和首次部署。首次登录后应立即执行 `passwd`，长期运行或暴露到其他网络前应更换强密码、改用公钥或关闭 SSH。

### 阶段 5：打印机热插拔与首次配置

采用 `eudev` 而不是默认 `mdev`，以降低移植 foo2zjs 热插拔规则的工作量。

系统逻辑分为：

1. udev 检测 HP USB ID。
2. 等待 `/dev/usb/lp0` 出现。
3. 暂停 CUPS 对设备的访问。
4. 将 `sihp1020.dl` 上传到打印机。
5. 等待打印机重新枚举。
6. 恢复 CUPS。
7. 检查 HP 1020 队列是否存在。
8. 如果不存在，则创建队列并设置为启用状态。

队列创建应放在首次启动服务中，而不是完全依赖镜像构建时的固定 USB URI。

### 阶段 6：生成镜像

使用本地构建出的 builder 容器，传入：

* `ARCH=armv7`
* `ALPINE_BRANCH=v3.23`
* `DEV=eudev`
* `ADDITIONAL_KERNEL_MODULES=usblp`
* 项目输入目录
* builder 缓存目录
* 输出目录

预期产物：

```text
sdcard.img.gz
sdcard.img.gz.sha256
sdcard_update.img.gz
sdcard_update.img.gz.sha256
build-manifest.json
packages-manifest.txt
```

builder 本身会生成完整镜像、更新镜像及校验文件。

### 阶段 7：自动验证

GitHub Runner 无法真正模拟 HP 1020 的 USB 固件上传，因此验证分为两级。

#### CI 自动验证

* APK 能在 armv7 Alpine 中安装。
* foo2zjs 可执行文件架构为 ARM EABI。
* PPD 文件存在。
* 固件文件存在且 SHA-256 正确。
* udev 规则和固件加载程序存在。
* `usblp` 模块包含在镜像中。
* CUPS、D-Bus、Avahi、eudev 已加入 OpenRC。
* 镜像分区可以被检查或挂载。
* `cupsfilter` 能将测试文档送入 foo2zjs 过滤链。
* 输出的 ZjStream 文件非空。
* 可选使用 QEMU `raspi2b` 进行启动冒烟测试。

foo2zjs 自带的完整 `make test` 对 Ghostscript 版本敏感，因此不能把它作为唯一 CI 验证标准。上游安装说明也明确提示不同 Ghostscript 版本可能造成测试不通过。

#### 真机验收

* Pi 2B 可以正常启动。
* 网络正常并能获得 DHCP 地址。
* `hp1020.local` 可解析。
* 打印机开启后自动加载固件。
* 打印机断电再开后可恢复。
* Windows、Linux 或 Android 客户端能发现打印服务。
* CUPS 测试页打印正常。
* 连续打印多个任务不会卡住队列。

---

## 五、项目文件结构

```text
hp1020-alpine-rpi/
├── .github/
│   └── workflows/
│       ├── build-image.yml
│       └── release-image.yml
│
├── config/
│   ├── build.env
│   ├── packages.txt
│   ├── sources.lock
│   ├── firmware-checksums.txt
│   └── image-version
│
├── packages/
│   └── foo2zjs/
│       ├── APKBUILD
│       ├── checksums/
│       ├── patches/
│       └── files/
│           ├── hp1020-firmware-loader
│           ├── hp1020-firstboot
│           ├── hp1020-openrc
│           └── hp1020-udev.rules
│
├── image/
│   ├── input/
│   │   ├── image.sh
│   │   ├── m4/
│   │   │   ├── fstab.m4
│   │   │   └── hdmi.m4
│   │   └── stages/
│   │       └── 60/
│   │           ├── 10-add-local-apk-repository.sh
│   │           ├── 20-install-print-stack.sh
│   │           ├── 30-configure-cups.sh
│   │           ├── 40-configure-hp1020.sh
│   │           ├── 50-configure-network.sh
│   │           ├── 60-configure-security.sh
│   │           └── 90-finalize.sh
│   │
│   └── rootfs/
│       ├── etc/
│       │   ├── cups/
│       │   ├── avahi/
│       │   ├── conf.d/
│       │   ├── init.d/
│       │   ├── modules-load.d/
│       │   └── udev/rules.d/
│       └── usr/
│           ├── local/libexec/
│           └── share/foo2zjs/firmware/
│
├── scripts/
│   ├── clone-sources.sh
│   ├── build-builder-container.sh
│   ├── build-foo2zjs-apk.sh
│   ├── fetch-hp1020-firmware.sh
│   ├── build-image.sh
│   ├── inspect-image.sh
│   ├── create-manifest.sh
│   └── qemu-smoke-test.sh
│
├── tests/
│   ├── test-package.sh
│   ├── test-image-layout.sh
│   ├── test-cups-filter.sh
│   ├── test-openrc-services.sh
│   └── assets/
│       └── test-page.pdf
│
├── docs/
│   ├── BUILDING.md
│   ├── FLASHING.md
│   ├── FIRST_BOOT.md
│   ├── WINDOWS_CLIENT.md
│   ├── LINUX_CLIENT.md
│   ├── TROUBLESHOOTING.md
│   └── FIRMWARE-LICENSE.md
│
├── output/
├── cache/
├── .gitignore
├── LICENSE
└── README.md
```

`vendor/` 目录不是必须提交。Workflow 可以把外部仓库分别 checkout 到临时工作目录，避免把大型上游仓库作为 Git submodule。

---

## 六、GitHub Actions 工作流划分

### Job 1：`lint`

检查：

* ShellCheck。
* APKBUILD 格式。
* YAML 格式。
* 文件权限。
* 禁止提交固件二进制。
* `sources.lock` 是否完整。

### Job 2：`build-foo2zjs`

依赖：

```text
lint
```

工作：

* 启用 QEMU arm/v7。
* Clone 固定版本的 foo2zjs。
* 构建 armv7 APK。
* 创建本地 APK 仓库。
* 上传 APK 和 APKINDEX 中间产物。

### Job 3：`build-image`

依赖：

```text
build-foo2zjs
```

工作：

* Clone 固定版本的 builder。
* 构建 builder Docker 镜像。
* 下载 foo2zjs APK Artifact。
* 获取并验证 HP 1020 固件。
* 执行镜像构建。
* 生成 manifest 和校验文件。

### Job 4：`verify-image`

依赖：

```text
build-image
```

工作：

* 检查镜像分区。
* 检查 rootfs 文件。
* 检查 ARM 架构。
* 检查 CUPS/OpenRC 配置。
* 检查 `usblp`。
* 运行打印过滤链测试。
* 可选执行 QEMU 启动测试。

### Job 5：`publish`

触发条件：

* Git tag。
* GitHub Release。
* 手动选择发布参数。

工作：

* 上传完整 SD 卡镜像。
* 上传 update 镜像。
* 上传 SHA-256。
* 上传包清单和源码版本清单。
* 生成 Release notes。

普通 push 只上传短期 Artifact，不创建公开 Release。

---

## 七、Workflow 触发方式

应支持：

```text
push:
  main 分支

pull_request:
  main 分支

workflow_dispatch:
  手动选择 Alpine 分支、是否启用 Avahi、是否运行 QEMU

schedule:
  可选，每月进行一次依赖可构建性检查

tags:
  v*
```

定时任务只验证构建，不自动发布新镜像。

---

## 八、版本锁定策略

`sources.lock` 至少记录：

* Alpine branch。
* builder commit SHA。
* foo2zjs commit SHA。
* Raspberry Pi firmware branch或commit。
* HP 1020 固件 SHA-256。
* builder Docker 基础镜像 digest。
* GitHub Actions commit SHA。
* 构建时间和项目版本。

正式 Release 必须能够根据 `sources.lock` 重建。

---

## 九、体积优化路线

第一版优先保证可用性，不要过早裁剪。

确认真机打印正常后，再进行：

* 移除文档和 man page。
* 移除编译工具。
* 移除不需要的字体。
* 只保留 HP 1020 需要的 PPD 和 foo2zjs 二进制。
* 只保留 `usblp` 等必要内核模块。
* 关闭不需要的 Avahi 或 SSH。
* 调整 Root A、Root B 和 data 分区大小。
* 评估把 eudev 替换为 mdev 的收益。

由于 Ghostscript 在 armv7 上安装体积较大，完整 CUPS 驱动模式不会像 p910nd 那样只有十几兆，但客户端可以直接发送 PDF、PostScript 或普通 CUPS 任务。

---

## 十、Codex 实施顺序

Codex 应按照以下顺序提交代码：

1. 创建项目目录、配置文件和文档骨架。
2. 完成上游仓库 clone 和版本锁定。
3. 完成 foo2zjs APKBUILD。
4. 在 GitHub Actions 中成功生成 armv7 APK。
5. 完成 HP 1020 固件获取和校验流程。
6. 完成 builder Stage 60 系统定制。
7. 成功生成 `sdcard.img.gz`。
8. 加入镜像静态检查。
9. 加入 CUPS 过滤链测试。
10. 加入 Release 工作流。
11. 在 Raspberry Pi 2B 真机验证。
12. 真机验证后再进行体积裁剪。

不要同时实现驱动打包、镜像构建、QEMU 和 Release。每完成一个阶段，都应保留一个可以独立运行的 Workflow。

---

## 十一、最终验收标准

项目完成必须满足：

* GitHub Actions 在标准 Ubuntu Runner 上构建成功。
* 不需要自建 ARM Runner。
* 输出 Raspberry Pi 2B `armv7` 镜像。
* 镜像启动后 CUPS 自动运行。
* HP 1020 热插拔后自动上传固件。
* 打印机断电重启后无需人工执行命令。
* 局域网客户端可以通过 IPP 使用打印机。
* 默认可通过 `root/1234` 首次 SSH 登录，并在文档中明确要求首次登录后修改密码。
* 构建产物附带 SHA-256 和源码版本清单。
* 公开仓库不直接保存未经确认可再分发的 HP 固件。
