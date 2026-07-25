# 写入 SD 卡

先校验：

```sh
cd output/image
sha256sum -c sdcard.img.gz.sha256
```

确认目标设备后写入。下面的 `/dev/sdX` 必须替换为整张 SD 卡，不能是分区：

```sh
gzip -dc sdcard.img.gz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
sync
```

该操作会覆盖目标设备。写入前用 `lsblk` 再次核对容量和设备名。Windows 可解压 `.gz` 后使用 Raspberry Pi Imager 的“Use custom”功能。

完整镜像包含 Boot、Root A、Root B、Data 四个分区。Boot 与 rootfs
默认以可写方式挂载，系统配置修改会直接写入当前活动 root 分区。日后系统升级可使用
`sdcard_update.img.gz` 写入未激活 root 分区，但必须先确认当前活动分区，不能直接覆盖
正在运行的 rootfs；切换到另一根分区时，当前根分区上的修改不会自动同步。
