# Strikergy 3v3

Strikergy 的 Booster K1 RoboCup 3v3 比赛源码仓库。

当前主线以 K1 5v5 Demo 1.7 为基础，保留新版 GameController v20、TensorRT 真机视觉和 kV2 起身支持，并将默认参赛人数调整为 3。

## 当前默认配置

- Team ID: `70`
- Player ID: `1`
- Player role: `striker`
- Number of players: `3`
- Field type: `adult_size`（14.16 m × 9.22 m）

固定角色命名：1 号 `striker`、2 号 `supporter`、3 号 `keeper`。

每台机器人部署前必须单独设置唯一的 `player_id` 和正确的 `player_role`。裁判机 IP 白名单也应按现场网络修改，不要直接把同一份机器人身份配置复制到全队。

## 可选场地

默认仍为 `adult_size`。新增 `ssl_division_b`，采用 SSL B 组的场地几何：

| 配置名 | 比赛区域（长 × 宽） | 球门宽 | 中圈半径 | 防守区（深 × 宽） |
|---|---|---|---|---|
| `ssl_division_b` | 9 × 6 m | 1 m | 0.5 m | 1 × 2 m |
| `kid_size`（原有） | 9 × 6 m | 2.6 m | 0.75 m | 大禁区 2 × 5 m，小禁区 1 × 3 m |

SSL B 组不是 `kid_size` 的别名。其定位地图仅保留一个防守区，并包含球门到球门的纵向中轴标线；罚球点距目标球门 6 m。策略中的球门区尺寸复用防守区，但不会生成第二套重叠标线。
尺寸依据：[SSL 官方规则（2026-05-21）](https://robocup-ssl.github.io/ssl-rules/sslrules.html)。

**机器人更新代码并重新编译后**，可在正常启动时选择：

```bash
./scripts/start.sh field_type:=ssl_division_b
```

此命令会启动比赛程序，应遵循下方的现场安全与遥控器接管要求。这里只增加场地选项，不自动启动或部署机器人。

也可将 `src/brain/config/config.yaml` 中 `brain_node.ros__parameters.game.field_type` 改为 `"ssl_division_b"`，然后重新构建以更新安装目录配置。若存在 `config_local.yaml`，其中的同名参数会覆盖基础配置；启动参数优先级最高。不传 `field_type` 时继续使用已有配置。所有参赛机器人必须选择相同场地。

这个选项只切换场地几何，仍使用 K1 3v3 策略、现有视觉模型和 GameController v20；不是切换到 SSL 的轮式机器人、SSL-Vision 或裁判机协议。1 cm 标线和 16 cm 高的 SSL 球门能否被现有模型稳定识别，需要现场验证。`src/vision/config/field.yaml` 是相机标定用的实测坐标，不是比赛地图预设，不应直接套用到新场地标定。

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

机器人从开机、SSH 检查、编译、启动、入场定位、遥控器操作到裁判机比赛状态的完整说明，参见 [机器人开机与比赛操作流程](docs/ROBOT_STARTUP_GUIDE.md)。

## 部署原则

本仓库是策略代码的唯一主版本。修改先提交并推送到 GitHub；机器人开机后再从对应提交同步、编译和现场验证。

模型文件与预编译库不上传到公开仓库。部署时先准备原始 K1 Demo 1.7 环境，再将本仓库源码同步到机器人，保留机器人本地的 TensorRT 模型和平台依赖库。
