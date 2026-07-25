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

## RTL8822CU 或 RTL8811CU 网卡没有出现

先确认 USB 设备、驱动和固件：

```sh
lsusb
modprobe rtw88_8822cu
modprobe rtw88_8821cu
lsmod | grep rtw88
find /lib/firmware/rtw88 \
  \( -name 'rtw8822c_fw.bin*' -o -name 'rtw8821c_fw.bin*' \)
dmesg | grep -E 'rtw88|8821|8822|firmware'
ip link
```

如果 `modprobe` 报模块不存在，应检查镜像中的 `linux-rpi` 版本以及构建时
`ADDITIONAL_KERNEL_MODULES` 是否仍包含对应的 `rtw88_8822cu` 或
`rtw88_8821cu`。

## RTL8822CU 或 RTL8811CU 已出现但没有联网

这类 Realtek USB 网卡可能先以 `0bda:1a2b` 存储设备模式出现，稍后才切换
成无线网卡。镜像通过 udev 在 `wlan0` 出现时触发 Wi-Fi 启动，检查：

```sh
rc-service wpa_supplicant status
iw dev wlan0 link
ip addr show wlan0
grep -v 'psk=' /etc/wpa_supplicant/wpa_supplicant.conf
/usr/libexec/wifi-hotplug wlan0
dmesg | grep -E 'wlan0|wpa|rtw|8821|8822'
```

`/etc/network/interfaces` 中应保留 `iface wlan0 inet dhcp`，但不要添加
`auto wlan0`，否则开机时 `wlan0` 尚未出现会导致 `networking` 过早失败。

## 作业卡住

```sh
cancel -a hp1020
rc-service cupsd restart
```

随后关闭打印机十秒再开。不要在 CUPS 占用 `/dev/usb/lp0` 时手动 `cat` 固件，加载器会先暂停 CUPS。

## 镜像构建空间不足

清理 Docker 的无关缓存，保留 `cache/builder`。完整镜像包含两个 root 分区，Runner 应至少保留 15 GB 空间。
