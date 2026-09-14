# Strikergy 3v3

Strikergy 的 Booster K1 RoboCup 3v3 比赛源码仓库。

当前主线以 K1 5v5 Demo 1.7 为基础，保留新版 GameController v20、TensorRT 真机视觉和 kV2 起身支持，并将默认参赛人数调整为 3。

## 当前默认配置

- Team ID: `70`
- Player ID: `1`
- Player role: `striker`
- Number of players: `3`
- Field type: `robo_league`

每台机器人部署前必须单独设置唯一的 `player_id` 和正确的 `player_role`。裁判机 IP 白名单也应按现场网络修改，不要直接把同一份机器人身份配置复制到全队。

## 构建

```bash
./scripts/build.sh
```

## 启动

机器人必须位于安全、平整且无人的测试区域，并由操作员持遥控器准备接管：

```bash
./scripts/start.sh
```

停止：

```bash
./scripts/stop.sh
```

## 部署原则

本仓库是策略代码的唯一主版本。修改先提交并推送到 GitHub；机器人开机后再从对应提交同步、编译和现场验证。

模型文件与预编译库不上传到公开仓库。部署时先准备原始 K1 Demo 1.7 环境，再将本仓库源码同步到机器人，保留机器人本地的 TensorRT 模型和平台依赖库。
