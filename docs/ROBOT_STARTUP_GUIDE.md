# 机器人开机与比赛操作流程

本文适用于 Strikergy 的 Booster K1 3v3 队伍。当前固定分工为：

| 机器人 | 机身编号 | `player_id` | `player_role` | 职责 |
| --- | --- | ---: | --- | --- |
| 1 号 | `60035`（完整序列号尾号） | `1` | `striker` | 主前锋，优先追球和进攻 |
| 2 号 | `60023`（完整序列号尾号） | `2` | `supporter` | 支援前锋，主攻手控球时主动让位和接应 |
| 3 号 | 待登记 | `3` | `keeper` | 固定守门员 |

> 机器人编号以机身序列号为准，IP 可能随网络变化，不能把某个 IP 永久当作机器人编号。当前已确认：序列号尾号 `60035` 是 1 号，尾号 `60023` 是 2 号。

> 安全要求：机器人必须放在平整、宽阔、无人的区域，操作员全程拿着遥控器，并能随时按 `L2 + X` 停止自动策略。第一次运行、修改策略或更新固件后，先单机空场测试，不要直接三机同时上场。

## 一、每次开机前检查

1. 检查电量、急停状态、关节和相机是否正常，清除机器人周围障碍物。
2. 确认机器人、裁判机电脑和操作电脑连接到同一个局域网。
3. 确认三台机器人使用不同 IP；不要只凭昨天的 IP 判断机器人编号，开机后应重新核对。
4. 把机器人放在己方半场规定的入场边线附近，机身朝向场内。为了提高定位成功率，场地线应清晰可见且不要被人员遮挡。
5. 遥控器开机、连接机器人，并由一名操作员负责安全接管。

## 二、连接机器人并核对环境

从操作电脑连接机器人：

```bash
ssh booster@<机器人IP>
```

连接后检查固件/CLI 版本：

```bash
booster-cli version
```

连接多台机器人时，先根据机身标签或设备序列号核对身份；不要只根据 IP 判断。当前固定映射为：

```text
60035 -> 1号 -> player_id 1 -> striker
60023 -> 2号 -> player_id 2 -> supporter
3号   -> player_id 3 -> keeper（机身编号待登记）
```

进入部署目录。下方以 `/home/booster/Workspace/Strikergy-3v3` 为例；如果真机上的文件夹名称不同，请替换成实际路径：

```bash
cd /home/booster/Workspace/Strikergy-3v3
pwd
```

每台机器人首次部署时，在仓库根目录创建一次本机身份文件。该文件已被 Git 忽略，后续 `git pull` 不会覆盖：

```bash
# 仅在机身编号尾号为 60035 的 1 号机器人执行
printf '60035\n' > .robot_identity

# 仅在机身编号尾号为 60023 的 2 号机器人执行
printf '60023\n' > .robot_identity
```

不要在同一台机器人上同时执行两条命令。创建后检查自动映射结果：

```bash
./scripts/select_robot_config.sh
```

预期分别输出 `player_id=1, player_role=striker` 或 `player_id=2, player_role=supporter`。身份缺失或未知时，`start.sh` 会在停止任何服务之前拒绝启动，防止两台机器人使用相同的 `player_id`。

重点确认：

- 三台机器人的 `team_id` 必须一致，且与裁判机设置一致；当前默认值为 `70`。
- `number_of_players` 应为 `3`。
- 1、2、3 号的 `player_id` 必须分别为 `1`、`2`、`3`，不能重复。
- 1 号使用 `player_role: "striker"`。
- 2 号使用 `player_role: "supporter"`。
- 3 号使用 `player_role: "keeper"`。
- `fixed_goalie_player_id` 应为 `3`。
- `field_type` 必须与实际场地匹配；当前使用 `adult_size`（14.16 m × 9.22 m）。

## 三、首次部署或代码更新后编译

如果只是关机后重新开机，且代码、依赖和配置都没有变化，可以跳过本节。

首次部署、从 GitHub 同步了新代码，或者修改了 C++/ROS 消息后，应在机器人上重新编译：

```bash
cd /home/booster/Workspace/Strikergy-3v3
./scripts/stop.sh
source /opt/ros/humble/setup.bash
export CUDACXX=/usr/local/cuda-12.6/bin/nvcc
export PATH=/usr/local/cuda-12.6/bin:$PATH
./scripts/build.sh
```

等待终端出现 `Build complete`，并确认没有 `Failed`、`error` 或缺少依赖/模型的提示。

上述 ROS 2 和 CUDA 环境变量是在当前两台真机上验证过的。首次全量编译通常需要约 5～8 分钟；只修改 `src/brain` 策略后增量编译通常为几十秒到 2 分钟；只修改 `config.yaml` 不需要重新编译，停止并重新启动 Demo 即可生效。

每次比赛前还应确认机器人当前代码确实来自本队 GitHub：

```bash
git remote -v
git branch -vv
git rev-parse --short HEAD
git status --short
```

远程仓库应为 `https://github.com/Liuxiang-hub/Strikergy-3v3.git`。两台机器人共用同一策略提交；本机的 `.robot_identity` 自动选择 `configs/robots/<机身编号>.conf`，并在启动时覆盖公共 `config.yaml` 中的默认 `player_id` 和 `player_role`。因此不要提交 `.robot_identity`，也不要为了区分机器人而分别修改公共配置。

本 GitHub 仓库只保存策略源码，不包含真机 TensorRT/ONNX 模型和部分平台依赖。部署时必须以已经能运行的 K1 Demo 1.7 真机环境为基础，保留机器人本地的模型、SDK 和预编译依赖。仅仅“编译通过”不代表已经具备完整比赛条件。

## 四、启动比赛程序

启动前先保证机器人站稳、周围无人，然后执行：

```bash
cd /home/booster/Workspace/Strikergy-3v3
./scripts/start.sh
```

`start.sh` 会先验证 `.robot_identity` 并显示选中的机器人编号、`player_id` 和角色；验证通过后才会停止可能冲突的旧进程，然后启动：

1. `vision`：识别足球、场地标线、交点、门柱和机器人。
2. `brain`：运行 `game.xml` 比赛行为树。
3. `game_controller`：接收裁判机发出的 RoboCup UDP 比赛状态。

程序在后台运行，日志写在当前目录：

```bash
tail -f brain.log
tail -f vision.log
tail -f game_controller.log
```

可另开 SSH 窗口查看 ROS 2 节点和裁判机话题：

```bash
cd /home/booster/Workspace/Strikergy-3v3
source install/setup.bash
ros2 node list
ros2 topic info -v /robocup/game_controller
```

正常情况下应能看到视觉、Brain 和 GameController 相关节点。三机测试时，还要确认机器人之间的通信正常。

## 五、遥控器进入自动程序

程序启动后，比赛行为树默认处于自动策略状态，但比赛运动仍受裁判机的停止状态控制。遥控器组合键如下：

> 本队手柄的实体按键标记为 `L2`；它对应程序消息中的 `LT`（Left Trigger）。下表统一按手柄上实际可见的 `L2` 标记书写。左上方的 `L` 键对应程序中的 `LB`，不是 `L2`。

| 按键 | 状态 | 用途 |
| --- | --- | --- |
| `L2 + X` | `control_state = 1` | 立即取消自动策略并把速度置零；异常时优先使用 |
| `L2 + A` | `control_state = 2` | 清除当前定位并重新执行入场定位 |
| `L2 + B` | `control_state = 3` | 进入/恢复自动比赛策略 |

推荐现场顺序：

1. 程序启动后先按 `L2 + X`，保证机器人处于人工安全停止状态。
2. 把机器人摆到己方半场的入场边线附近，机身基本朝向场内。
3. 按 `L2 + A` 开始重新定位。
4. 机器人会站立、转动头部扫描场地，并尝试识别 L/T/X 交点和罚球点。此时不要推拉或旋转机器人。
5. 等待数秒，观察它是否停止大范围扫场，并检查 `brain.log` 中是否有定位成功信息。不能确认定位时，不要进入自动比赛。
6. 按 `L2 + B` 恢复自动策略。
7. 此时机器人仍会服从裁判机状态；如果裁判机仍处于 Stop/INITIAL，它不会直接冲出去踢球。

摇杆发生明显输入时会临时触发人工接管；摇杆回中后，自动行为是否恢复取决于当前 `control_state` 和裁判机状态。比赛现场不要误碰摇杆或使用 `L2 + Y`，后者会临时切换前锋/守门员角色，与固定 3 号守门员方案冲突。

## 六、定位完成后裁判机流程

比赛程序严格按照裁判机状态运行：

| 裁判机状态 | 机器人行为 |
| --- | --- |
| `INITIAL` | 在入场位置扫描场地、建立绝对定位 |
| `READY` | 根据 `player_id` 和角色走到本机开球站位，并持续修正定位 |
| `SET` | 停止行走、观察足球、等待开赛 |
| `PLAY` | 1 号 `striker` 主攻，2 号 `supporter` 接应，3 号 `keeper` 守门 |
| `END` | 停止运动 |
| 罚下/替补 | 停止；重新放回边线后需要再次定位 |

推荐自测顺序：

```text
INITIAL → READY → SET → PLAY → END
```

每次只切换一个状态，确认三台机器人的动作正确后再继续。进入 `READY` 后机器人会自主走向站位，因此人员必须退出场地并保留安全距离；进入 `PLAY` 后会自主追球、移动和踢球。

## 七、没有正式裁判机时测试

可以在同一局域网内运行本地 RoboCup GameController，设置：

- Team ID：`70`（或与机器人配置一致的值）。
- 每台机器人的 Player ID：分别为 `1`、`2`、`3`。
- 三台机器人和裁判机电脑必须位于允许 UDP 广播/组播通信的同一网络。

先做单机状态测试，再做三机联调。不要为了让机器人动起来而直接跳到 `PLAY`；应完整测试 `INITIAL → READY → SET → PLAY`，这样才能发现定位、站位、角色和裁判机通信问题。

## 八、停止程序和关机

比赛结束或发生异常时：

1. 先按 `L2 + X`，确认机器人停止。
2. 在 SSH 终端停止 Demo：

```bash
cd /home/booster/Workspace/Strikergy-3v3
./scripts/stop.sh
```

3. 确认相关节点已经退出：

```bash
ps -ef | grep -E "vision_node|brain_node|game_controller" | grep -v grep
```

4. 按 Booster 官方关机流程关机。不要在机器人仍然行走或踢球时直接断电。

## 九、常见故障检查

### 按 `L2 + B` 后机器人不动

依次检查：

1. 裁判机是否仍在 Stop、INITIAL、SET、END 或罚下状态。
2. 是否已经按过 `L2 + A` 并成功定位。
3. `brain`、`vision`、`game_controller` 节点是否都在运行。
4. `brain.log` 和 `game_controller.log` 是否有报错。
5. 遥控器摇杆是否没有完全回中，导致程序仍处于人工接管。

### 一直左右扫头，不能定位

- 把机器人放到正确的己方入场边线位置，并朝向场内。
- 确保视野中能看到足够多的清晰场地交点，当前粒子定位至少需要 4 个有效地标。
- 检查 `field_type` 是否与实际场地一致。
- 清除遮挡，改善照明，检查相机画面和视觉日志。
- 重新按 `L2 + X`，摆正机器人后再按 `L2 + A`。

### 机器人跑向错误球门

立即按 `L2 + X`。这通常意味着入场方向、场地边线、队伍颜色/半场信息或绝对定位出现错误。不要直接再次按 `L2 + B`；先核对裁判机配置，把机器人放回正确入场位置，然后执行 `L2 + A` 重新定位。

### 三台机器人抢同一个球或角色错误

- 检查三台机器人的 `player_id` 是否唯一。
- 检查 `number_of_players: 3`、`enable_com: True` 和 `fixed_goalie_player_id: 3`。
- 检查 1 号是否为 `striker`、2 号是否为 `supporter`、3 号是否为 `keeper`。
- 确认三台机器人能互相通信，且裁判机 Team ID 一致。
- 确认没有误按 `L2 + Y` 改变运行时角色。

## 十、比赛前最终清单

- [ ] 三台机器人电量足够、机械和相机正常。
- [ ] 机器人、裁判机和操作电脑在同一网络。
- [ ] Team ID 与裁判机一致。
- [ ] Player ID 分别为 1、2、3，无重复。
- [ ] 角色分别为 1 号 `striker`、2 号 `supporter`、3 号 `keeper`。
- [ ] 三台机器人的代码提交版本一致。
- [ ] 真机模型、SDK、固件与 Demo 1.7 环境匹配。
- [ ] 编译成功，三个核心节点均正常运行。
- [ ] 每台机器人都完成入场定位。
- [ ] `INITIAL → READY → SET → PLAY → END` 全流程测试通过。
- [ ] `L2 + X` 急停式策略停止经过实测，现场操作员清楚按键。
- [ ] 三机通信、双前锋分工和固定守门员行为经过空场验证。
