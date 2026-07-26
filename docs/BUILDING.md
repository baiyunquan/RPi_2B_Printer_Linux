# 构建

## 环境

推荐 Ubuntu 24.04 x86_64，至少 15 GB 可用空间，并安装：

```text
docker
git
curl
gcc
tar
gzip
util-linux
```

跨架构执行依赖 arm/v7 binfmt。GitHub Actions 使用 `docker/setup-qemu-action` 自动配置；本地可使用发行版的 `qemu-user-static`。

克隆仓库时必须初始化 submodule：

```sh
git clone --recurse-submodules https://github.com/baiyunquan/RPi_2B_Printer_Linux.git
cd RPi_2B_Printer_Linux
scripts/clone-sources.sh
```

## 完整构建

```sh
scripts/build-foo2zjs-apk.sh
tests/test-package.sh
tests/test-cups-filter.sh
scripts/fetch-hp1020-firmware.sh
scripts/build-image.sh
sudo scripts/inspect-image.sh
```

`build-foo2zjs-apk.sh` 在 arm/v7 Alpine 容器内运行 `abuild`，输出三个已签名包和 APKINDEX。`build-image.sh` 直接从锁定的 `vendor/builder` submodule 构建 builder 容器，不使用浮动的 `latest` 镜像。固件转换工具来自锁定的 `vendor/foo2zjs` submodule。

RTL8822CU 使用 `linux-rpi` 6.12 自带的 `rtw88_8822cu`。RTL8811CU 在
Stage 60 从锁定的 `RTL8811CU_Driver` submodule 编译 `8821cu.ko`；
`linux-rpi-dev` 与 `linux-rpi` 使用完全相同的锁定版本，编译依赖会在安装
模块并运行 `depmod` 后删除。Stage 70 保留两个模块及其依赖。可通过
`RTL8811CU_BUILD_JOBS` 调整厂商驱动的并行编译数，默认值为 2。

生成的 Boot、活动 rootfs 和备用 rootfs 分区均按可写方式挂载。`/etc`
继续使用 data 分区上的持久化 overlay；这不会把 rootfs 设为只读，并可让配置在
A/B rootfs 切换后继续生效。A/B 分区结构仍然保留。CUPS 配置在镜像组装阶段通过
`cupsd -t` 校验。

默认分区为 Boot 32 MiB、Root A 256 MiB、Root B 256 MiB、Data 64 MiB，
生成的原始 IMG 约 610 MiB。Root 文件系统在打包时还会缩小到实际所需容量；
首次启动时，末尾的 Data 分区会扩展到 SD 卡剩余空间。若加入更多软件包，应同步
增大 `SIZE_ROOT_PART`，避免镜像创建阶段空间不足。

## 构建参数

默认值位于 `config/build.env`。常用覆盖：

```sh
ENABLE_AVAHI=false scripts/build-image.sh
```

镜像默认启用 Dropbear SSH，root 默认密码为 `1234`。可额外写入公钥：

```sh
SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/id_ed25519.pub)" \
scripts/build-image.sh
```

如需关闭 SSH：

```sh
ENABLE_SSH=false scripts/build-image.sh
```

默认密码仅适合受信任的隔离内网。首次登录后应立即运行 `passwd` 修改 root 密码。

## 私有固件

```sh
HP1020_FIRMWARE_FILE=/secure/sihp1020.dl \
  scripts/fetch-hp1020-firmware.sh
```

GitHub Actions 可使用 `HP1020_FIRMWARE_B64` secret。其内容是 `sihp1020.dl` 的 base64，不是明文文件路径。无 secret 时，Workflow 使用公开下载模式并严格校验 SHA-256。

## 更新锁

升级上游时必须同时更新：

- `config/sources.lock`
- `packages/foo2zjs/APKBUILD` 的 `_commit` 与 sha512
- `RTL8811CU_Driver` submodule commit 与内核 6.12 编译兼容性
- 固件来源变化时的三层校验值
- README 或兼容性说明

升级后先让 APK Workflow 独立通过，再构建镜像。
