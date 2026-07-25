# 首次启动与真机验收

1. 在打印机断电、USB 已连接的情况下启动 Raspberry Pi 2B。
2. 等待 DHCP 分配地址，尝试 `ping hp1020.local`。
3. 执行 `ssh root@hp1020.local`，使用默认密码 `1234` 登录，并立即运行 `passwd` 修改密码。
4. 给 HP LaserJet 1020 通电。
5. 查看 `dmesg`，应出现 `hp1020` 固件上传记录和 USB 重枚举。
6. 打开 `http://hp1020.local:631/printers/hp1020`；管理页面为
   `http://hp1020.local:631/admin`，使用 root 系统账户认证。
7. 打印 CUPS 测试页。

设备上可执行：

```sh
rc-service cupsd status
rc-service dbus status
rc-service avahi-daemon status
lpstat -t
lsmod | grep usblp
dmesg | grep hp1020
```

必须再测试一次断电恢复：保留 Pi 运行，只关闭打印机，等待十秒后重新开机。队列应自动恢复，无需手动执行固件命令。

最终验收还包括连续打印至少五个任务、Windows/Linux 客户端各一次、Pi 冷启动一次。CI 通过不能替代这些真机项目。
