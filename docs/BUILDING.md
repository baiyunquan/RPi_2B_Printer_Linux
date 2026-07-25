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

## 完整构建

```sh
scripts/build-foo2zjs-apk.sh
tests/test-package.sh
tests/test-cups-filter.sh
scripts/fetch-hp1020-firmware.sh
scripts/build-image.sh
sudo scripts/inspect-image.sh
```

`build-foo2zjs-apk.sh` 在 arm/v7 Alpine 容器内运行 `abuild`，输出三个已签名包和 APKINDEX。`build-image.sh` 从锁定 commit 构建 builder 容器，不使用浮动的 `latest` 镜像。

## 构建参数

默认值位于 `config/build.env`。常用覆盖：

```sh
ENABLE_AVAHI=false scripts/build-image.sh
```

启用 SSH 必须同时传入公钥：

```sh
ENABLE_SSH=true \
SSH_AUTHORIZED_KEYS="$(cat ~/.ssh/id_ed25519.pub)" \
scripts/build-image.sh
```

镜像中 root 密码始终被锁定。不要通过修改 builder 默认密码来开启远程登录。

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
- 固件来源变化时的三层校验值
- README 或兼容性说明

升级后先让 APK Workflow 独立通过，再构建镜像。
