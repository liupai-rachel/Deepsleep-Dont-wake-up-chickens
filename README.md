# 夜访鸡舍

[English](README.en.md)

## 项目详情

《夜访鸡舍》是一款单人俯视角潜行游戏。夜里潜入鸡舍，趁母鸡转身时搜蛋。你要在 **120 秒内收集至少 6 枚鸡蛋并从南侧绿色入口撤离**。多搜一次也许就能凑齐鸡蛋，也可能让农夫发现你。

- **搜蛋**。每个鸟巢藏有 1～3 枚蛋，巢上的标记只显示是否搜过、是否已空。靠近后按住 **E** 搜寻，每两秒取一枚蛋。搜寻期间无法移动，松手会取消本次未完成的进度。
- **躲避与引开**。三只母鸡在鸡舍里巡逻，视野扇形随朝向变化。墙壁和木箱能挡住视线，搜寻声仍可能被听见。轻按 **E** 拾取饲料，用 **Q** 朝前投放，可以暂时引开附近的母鸡。
- **警戒与撤离**。被母鸡看见或引发鸣叫会提高警戒。警戒达到 **60** 后，农夫从北侧入场，失去视线后会调查最后目击点。躲到掩体后停止搜寻，可以等警戒下降。鸡蛋达标后，在南侧入口轻按 **E** 撤离。被抓或超时会结束本局。
- **像素鸡舍与双语界面**。暖金色地面、蓝色夜景、木箱草垛和青瓦鸡窝组成默认固定关卡；鸟巢库存和巡逻变化仍由种子决定。可在 Layout 中关闭 Use Fixed Layout 恢复随机布局。开始、暂停和结算界面支持切换简体中文与英文。

## 项目架构

**Godot 4.5.1 Standard（导出模板同版本） · GDScript · Compatibility 渲染器 · 960×540**

[project.godot](project.godot) 保存项目配置，并指定 [game.tscn](game.tscn) 为主场景。主场景组装地图、角色和界面，各模块负责各自的规则。

| 模块 | 入口与职责 |
| --- | --- |
| 对局流程 | [game.gd](game.gd) 管理本局种子、倒计时、搜寻、农夫入场、胜负和重开。 |
| 地图与寻路 | [coop_layout.gd](scenes/coop_layout.gd) 生成布局、检查可达性并构建导航网格。随机生成多次失败时，使用经过验证的固定地图。[coop_navigation.gd](scenes/coop_navigation.gd) 为农夫和追饵的母鸡提供绕行路径。 |
| 角色与警戒 | [玩家](scenes/player.gd) 处理移动和朝向。[母鸡](scenes/chicken.gd) 处理巡逻、感知和啄食。[农夫](scenes/farmer.gd) 处理追赶、搜寻和撤退。[alert.gd](scenes/alert.gd) 管理警戒的增长与衰减。 |
| 鸟巢与饲料 | [nest.gd](scenes/nest.gd) 管理单个鸟巢的库存和状态。[feed_field.gd](scenes/feed_field.gd) 管理饲料拾取、持有数量和投放验证。 |
| 界面与反馈 | [round_hud.tscn](scenes/round_hud.tscn) 定义界面布局，[round_hud.gd](scenes/round_hud.gd) 更新状态并处理语言切换。[en.po](assets/i18n/en.po) 保存英文译文，[round_audio.tscn](scenes/round_audio.tscn) 绑定游戏提示音。 |

`scenes/` 保存可在编辑器中查看的场景和行为脚本。`assets/` 存放原创美术和音效、字体与翻译。UI 字体是 Noto Sans SC 子集，采用 [SIL 开源字体许可](assets/fonts/OFL.txt)。

各文件的详细用途见 [项目文件说明](PROJECT_GUIDE.md)。
