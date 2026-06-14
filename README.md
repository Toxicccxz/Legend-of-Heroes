# Legend of Heroes

一个 Flutter 编写的文字 RPG / MUD 原型。项目把界面、游戏状态、游戏规则和内容数据分开组织，当前包含地图探索、NPC 对话、任务进度、背包、装备、门派、技能、事件触发和本地存档等基础系统。

## 运行环境

- Flutter 3.29.3
- Dart 3.7.2
- Android Studio / VS Code 均可开发

确认环境：

```sh
flutter --version
flutter doctor
```

## 安装依赖

```sh
flutter pub get
```

## 运行项目

列出可用设备：

```sh
flutter devices
```

运行到默认设备：

```sh
flutter run
```

运行到指定平台或设备：

```sh
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>
```

## 验证

提交或修改核心逻辑前，优先运行：

```sh
flutter analyze
flutter test
```

当前测试覆盖了游戏状态、地图系统、地图数据完整性、事件、任务、背包、物品使用、存档和基础 Widget 流程。

## 项目结构

```text
lib/
  main.dart
  game/
    core/           游戏状态、控制器和用户动作
    data/           游戏数据加载编排
    models/         房间、NPC、物品、任务等数据模型
    repositories/   资源数据读取和 Hive 存档
    systems/        地图、任务、事件、背包、装备、对话等规则
  ui/
    screens/        开始界面和游戏主界面
    widgets/        状态面板、地图面板、消息面板和标签页
assets/
  data/             JSON 游戏内容数据
test/               单元测试和 Widget 测试
```

## 数据文件

游戏内容主要由 `assets/data/` 下的 JSON 文件驱动：

- `rooms.json`: 房间、出口、坐标、NPC 和房间事件
- `zones.json`: 区域信息和地图可见半径
- `npcs.json`: NPC 定义
- `dialogues.json`: NPC 对话和对话事件
- `items.json`: 物品、装备和使用事件
- `quests.json`: 任务定义和目标
- `events.json`: 进入房间、调查、休息、物品使用等事件
- `sects.json`: 门派定义
- `skills.json`: 技能定义

修改地图数据后建议运行：

```sh
flutter test test/map_data_integrity_test.dart
```

## 存档

存档通过 Hive 保存在本地，入口在 `lib/game/repositories/save_repository.dart`。运行时状态会保存玩家属性、当前位置、任务进度、背包、装备、访问过的房间、事件标记、日志和当前 UI 选择。

## 开发约定

- UI 放在 `lib/ui`。
- 游戏规则放在 `lib/game/systems`。
- 可配置内容优先放进 `assets/data`。
- 保持 `GameController` 作为动作分发入口。
- 新增规则时优先补对应系统测试。
