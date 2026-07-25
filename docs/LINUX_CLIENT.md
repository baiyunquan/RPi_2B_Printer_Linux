# Linux 客户端

支持 DNS-SD 的桌面通常会自动显示 “HP LaserJet 1020 on hp1020”。也可以直接添加：

```text
ipp://hp1020.local/printers/hp1020
```

命令行示例：

```sh
lpadmin -p hp1020-pi -E \
  -v ipp://hp1020.local/printers/hp1020 \
  -m everywhere
lp -d hp1020-pi document.pdf
```

服务器负责 Ghostscript 与 foo2zjs 转换，客户端通常无需安装 foo2zjs。
