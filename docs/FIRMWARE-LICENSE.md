# HP LaserJet 1020 固件许可

本仓库不包含、跟踪或许可 `sihp1020.img` / `sihp1020.dl`。

构建脚本仅实现以下操作：

1. 从配置的来源取得输入，或读取用户提供的私有文件。
2. 验证已知 SHA-256。
3. 使用 foo2zjs 的 `arm2hpdl` 生成打印机下载格式。
4. 将结果放入本次构建的镜像。

HP 固件的版权和再分发条件独立于本项目与 foo2zjs。公开发布包含固件的镜像前，维护者必须自行完成许可审查。Release Workflow 因此要求仓库变量：

```text
ALLOW_FIRMWARE_REDISTRIBUTION=true
```

没有该显式批准时，Workflow 会拒绝创建公开 Release。短期 GitHub Actions Artifact 也可能构成分发；组织策略不允许时，应配置 `HP1020_FIRMWARE_B64` 私有 secret，并限制 Actions/Artifact 访问，或停用 Artifact 上传。
