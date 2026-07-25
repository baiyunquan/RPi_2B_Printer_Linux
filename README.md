# HP LaserJet 1020 Alpine Raspberry Pi 打印服务器

本仓库为 Raspberry Pi 2B 构建可重复生成的 Alpine Linux `armv7` SD 卡镜像。镜像包含 CUPS、Ghostscript、cups-filters、foo2zjs、eudev，以及 HP LaserJet 1020 的自动固件加载与队列创建逻辑。

主要特性：

- `raspi-alpine/builder` 的可写 A/B rootfs、可写 Boot，以及承载 `/etc`
  overlay 的持久 Data 分区。
- 每次 HP 1020 通电或 USB 重连时自动加载 `sihp1020.dl`。
- 自动创建名为 `hp1020` 的 CUPS 队列，并通过局域网提供 IPP。
- 内置 RTL8822CU、RTL8811CU USB 无线网卡驱动及配套固件。
- 默认启用 Avahi，地址为 `hp1020.local`；可在构建时关闭。
- 默认启用 Dropbear SSH，允许使用 root 和密码 `1234` 登录。
- GitHub Actions 构建已签名的 armv7 APK、本地镜像、校验文件和版本清单。
- Git 永不跟踪 HP 固件或生成的镜像。

## 快速开始

在 Ubuntu 24.04 或其他具备 Docker、QEMU binfmt、Git、C 编译器的 Linux 主机上：

```sh
scripts/build-foo2zjs-apk.sh
scripts/fetch-hp1020-firmware.sh
scripts/build-image.sh
sudo tests/test-image-layout.sh
```

构建结果位于 `output/image/`：

```text
sdcard.img.gz
sdcard.img.gz.sha256
sdcard_update.img.gz
sdcard_update.img.gz.sha256
build-manifest.json
packages-manifest.txt
```

固件默认在构建时从 foo2zjs 当前使用的下载源获取，并按 `config/firmware-checksums.txt` 校验。也可设置 `HP1020_FIRMWARE_FILE=/安全路径/sihp1020.dl` 使用私有来源。详见 [构建说明](docs/BUILDING.md) 和 [固件许可说明](docs/FIRMWARE-LICENSE.md)。

## SSH 登录

设备启动并取得网络地址后，可直接登录：

```sh
ssh root@hp1020.local
```

默认密码为 `1234`。这是便于首次部署的弱密码，只应在受信任的隔离内网使用；投入长期运行前应立即执行 `passwd` 修改密码，或在构建时关闭 SSH。

## RTL8822CU、RTL8811CU 无线网卡

镜像使用 Linux 6.12 内核自带的 `rtw88_8822cu` 和 `rtw88_8821cu`
驱动；RTL8811CU 由后者支持，不安装第三方 DKMS 模块。构建过程会保留
这些模块及其依赖，并安装锁定版本的 `linux-firmware-rtw88`。插入网卡后
可用 `ip link` 查看无线接口。

## CUPS 管理

同一局域网内可打开 `http://hp1020.local:631/`。打印队列页面和
`/admin` 管理页面均允许局域网访问，管理操作使用系统账户
`root` 登录。镜像构建时会执行 `cupsd -t`，配置语法错误会直接终止构建。

## 版本锁定

[sources.lock](config/sources.lock) 固定 builder、foo2zjs、固件校验值和所有 GitHub Actions 的完整 commit SHA。builder 与 foo2zjs 同时作为 `vendor/` 下的 Git submodule 固定，构建脚本会拒绝 commit 不匹配的工作树。Raspberry Pi 启动固件采用 builder 的 `alpine` 模式，即来自 Alpine `linux-rpi` 包；对应关系记录在构建清单中。

## 使用限制

CI 可以验证 ARM 包、镜像分区、OpenRC 服务、`usblp` 模块和打印过滤链，但不能模拟真实 HP 1020 的 USB 固件重枚举。首次发布前仍须按 [真机验收步骤](docs/FIRST_BOOT.md) 在 Raspberry Pi 2B 上测试。

项目代码采用 Apache-2.0。foo2zjs 及 HP 固件分别受其上游许可约束。
