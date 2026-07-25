# Windows 客户端

优先使用 IPP：

```text
http://hp1020.local:631/printers/hp1020
```

在 Windows“设置 → 蓝牙和设备 → 打印机和扫描仪”中添加打印机。如果自动发现失败，选择手动添加并输入上述 URL。客户端驱动可选择 Microsoft IPP Class Driver；若应用输出异常，再改用 HP LaserJet 1020 驱动。

若 `.local` 无法解析，使用路由器 DHCP 页面找到 Pi 地址：

```text
http://192.168.x.x:631/printers/hp1020
```
