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
默认以可写方式挂载；`/etc` 的修改保存在 Data 分区的持久化 overlay 中，因此
切换 A/B rootfs 后仍会保留。默认布局约为 Boot 32 MiB、两个 Root 各 256 MiB、
Data 64 MiB，写入更大的 SD 卡后 Data 会在首次启动时扩展到剩余空间。日后系统
升级可使用 `sdcard_update.img.gz` 写入未激活 root 分区，但必须先确认当前活动
分区，不能直接覆盖正在运行的 rootfs。
