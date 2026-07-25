# 故障排查

## 没有 `hp1020.local`

检查 `rc-service avahi-daemon status`、网线、DHCP 和客户端 mDNS 支持。若构建时设置了 `ENABLE_AVAHI=false`，只能使用 IP 地址。

## 队列不存在

打印机必须在线，首次启动服务才能获得 USB URI。运行：

```sh
/usr/libexec/hp1020-firmware-loader
lpstat -t
```

查看 `dmesg` 中以 `hp1020:` 开头的消息。

## 固件未加载

检查：

```sh
sha256sum /usr/share/foo2zjs/firmware/sihp1020.dl
ls -l /dev/usb/lp0
lsmod | grep usblp
udevadm test /sys/class/usb/lp0
```

固件 SHA-256 应与 `config/sources.lock` 中的 `HP1020_FIRMWARE_DL_SHA256` 一致。

## 作业卡住

```sh
cancel -a hp1020
rc-service cupsd restart
```

随后关闭打印机十秒再开。不要在 CUPS 占用 `/dev/usb/lp0` 时手动 `cat` 固件，加载器会先暂停 CUPS。

## 镜像构建空间不足

清理 Docker 的无关缓存，保留 `cache/builder`。完整镜像包含两个 root 分区，Runner 应至少保留 15 GB 空间。
