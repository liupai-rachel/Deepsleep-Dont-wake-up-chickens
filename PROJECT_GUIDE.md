# 夜访鸡舍项目文件说明

用 **Godot 4.5.1 Standard** 导入 [project.godot](project.godot)，按 **F5** 会打开
[game.tscn](game.tscn)，由 [game.gd](game.gd) 组织整局玩法。可以先打开
`game.tscn` 看节点树，再按下表找到负责对应功能的场景和脚本。玩法与架构概览见
[中文版 README](README.md)或[英文版 README](README.en.md)。

## 根目录文件

| 文件 | 用途 |
| --- | --- |
| [project.godot](project.godot) | 项目总配置。指定主场景、960×540 设计尺寸、按键映射、碰撞层、翻译资源和 Compatibility 渲染器。改键位从这里入手。 |
| [game.tscn](game.tscn) | 主场景和编辑器里的固定地图。包含地面、外围墙、木箱、鸟巢、母鸡和巡逻点、饲料、玩家、撤离点与农夫入口，并挂载 HUD 和音频。 |
| [game.gd](game.gd) | 整局调度。生成种子和初始库存，管理倒计时和搜寻，把母鸡的发现与鸣叫传给警戒系统，触发农夫入场，并处理暂停、胜负和重开。鸡蛋目标、每局时间、搜寻时长和农夫入场阈值可在 `Game` 检查器里调整。 |
| [export_presets.cfg](export_presets.cfg) | Web、Linux、Windows 的导出预设。 |
| [README.md](README.md) · [README.en.md](README.en.md) | 中文和英文的玩法介绍与项目架构概览。 |
| [AGENTS.md](AGENTS.md) | 给代码助手的项目约定，包括 Godot 版本、导入与导出检查、构建产物和凭据管理。 |
| [.gitignore](.gitignore) | Git 忽略规则。目前排除 `.godot/`、`build/` 和 `.env`。 |

## `scenes/` 里的玩法文件

`.tscn` 保存节点、图形、碰撞体和检查器设置，适合在 Godot 编辑器中调整。
`.gd` 实现行为和规则。同名文件通常是同一功能的场景与脚本。

| 功能 | 文件 | 用途与修改入口 |
| --- | --- | --- |
| 玩家 | [player.tscn](scenes/player.tscn) · [player.gd](scenes/player.gd) | 场景定义外观、碰撞和搜寻光效。脚本处理移动、朝向、搜寻时锁定移动，以及投放饲料时使用的方向。 |
| 鸟巢 | [nest.tscn](scenes/nest.tscn) · [nest.gd](scenes/nest.gd) | 场景定义外观、高亮和状态标记。脚本管理单个巢的库存、扣蛋与交互半径。搜寻时长和最近鸟巢的选择由 `game.gd` 管理。 |
| 母鸡 | [chicken.tscn](scenes/chicken.tscn) · [chicken.gd](scenes/chicken.gd) | 场景定义外观、视野和状态提示。脚本管理巡逻、转向、视线遮挡、听觉、鸣叫冷却，以及追饵、啄食和恢复巡逻。 |
| 警戒 | [alert.gd](scenes/alert.gd) | 挂在主场景的 `Alert` 节点上。计算警戒涨幅、安静等待时间和下降速度，把数值限制在 0～100。`game.gd` 根据警戒决定农夫何时入场。 |
| 农夫 | [farmer.tscn](scenes/farmer.tscn) · [farmer.gd](scenes/farmer.gd) | 场景定义外观和碰撞。脚本处理追赶、调查最后目击点、撤退和抓捕。调整追赶速度、视距和搜寻时长时看这里。 |
| 饲料 | [feed.tscn](scenes/feed.tscn) · [feed.gd](scenes/feed.gd) · [feed_field.gd](scenes/feed_field.gd) | 前两份描述一份饲料，区分绿袋和投放后的谷粒。`feed_field.gd` 管理整局饲料，包括拾取、持有数量、投放距离和落点验证。 |
| 掩体 | [crate.tscn](scenes/crate.tscn) · [interior_wall.tscn](scenes/interior_wall.tscn) | 木箱和内部墙的可复用场景，包含图形和静态碰撞。调整尺寸后需一起检查角色通行、视野遮挡和导航绕行。 |
| 随机布局 | [coop_layout.gd](scenes/coop_layout.gd) | 按种子摆放物件、出生点和巡逻点，生成导航网格，验证可达性与开局安全。随机方案用完尝试次数后会回退到固定布局。 |
| 寻路 | [coop_navigation.gd](scenes/coop_navigation.gd) | 农夫与追饵母鸡共用的寻路工具。直线可通行时直接走，遇到障碍则通过导航网格找下一步方向。 |
| 界面 | [round_hud.tscn](scenes/round_hud.tscn) · [round_hud.gd](scenes/round_hud.gd) | 场景负责 HUD、开始、暂停和结算界面的排版。脚本负责数值与提示刷新、按钮事件和语言切换。 |
| 音效 | [round_audio.tscn](scenes/round_audio.tscn) · [round_audio.gd](scenes/round_audio.gd) | 场景把六段音效绑定到播放器。脚本负责播放、停止和关闭窗口时的音频清理。 |

## `assets/` 里的素材文件

| 文件 | 用途 |
| --- | --- |
| [coop_floor.svg](assets/art/coop_floor.svg) · [night_yard.svg](assets/art/night_yard.svg) · [lamplight.svg](assets/art/lamplight.svg) | 分别是鸡舍地板、夜间院子和灯光渐变。角色、箱子与鸟巢的图形主要画在各自的 `.tscn` 中。 |
| [search.wav](assets/audio/search.wav) · [egg.wav](assets/audio/egg.wav) · [cluck.wav](assets/audio/cluck.wav) | 分别是搜寻声、取蛋声和母鸡鸣叫。搜寻声的触发频率由 `game.gd` 控制。 |
| [farmer.wav](assets/audio/farmer.wav) · [success.wav](assets/audio/success.wav) · [failure.wav](assets/audio/failure.wav) | 分别是农夫入场、撤离成功和失败的提示音。 |
| [CoopUI.ttf](assets/fonts/CoopUI.ttf) · [OFL.txt](assets/fonts/OFL.txt) | 界面字体及其许可。字体是 Noto Sans SC 子集，新增中文文案后要检查新字能否显示。 |
| [en.po](assets/i18n/en.po) | 英文翻译表。中文原文是查找键，英文是译文。修改中文提示时同步更新对应条目，并保留 `%d`、`%s` 等占位符。 |

`*.gd.uid` 保存 Godot 的脚本资源标识，素材旁的 `*.import` 保存导入设置。
这两类文件应随对应源码或素材提交。Godot 会在本机重建 `.godot/imported/` 里的导入缓存。

## 构建与本地目录

- [.codex/setup.sh](.codex/setup.sh) 为 Linux 云环境安装 Godot 和匹配的导出模板，并执行无界面导入。
- [build.yml](.github/workflows/build.yml) 在 GitHub Actions 上检查并导出三平台。
  [package-release.sh](.github/scripts/package-release.sh) 将导出结果打包成发布压缩包。
  [deploy.yml](.github/workflows/deploy.yml) 用于手动部署 Web 版到 Cloudflare。
- `build/` 存放各平台构建，以及 `phase-*`、`playtest/` 等目录中的本机验收脚本、截图和日志。
  `build/.gdignore` 让 Godot 跳过扫描。Git 忽略整个 `build/`，组员拉取仓库时不会收到这里的构建或验收脚本。
- `.godot/` 是 Godot 缓存，`.vs/` 是 Visual Studio 的本机索引和工作区设置，`.git/` 是 Git 仓库数据。
  根目录下的 `export_templates/`、`feature_profiles/`、`script_templates/` 和 `text_editor_themes/` 是本机目录。
  实际导出模板由各自的 Godot 环境安装，版本须与 Godot 4.5.1 Standard 匹配。

## 分工与交接

- **关卡**从 `game.tscn` 入手。编辑器里移动箱子或鸟巢后，在 `Layout` 节点启用 **Use Fixed Layout** 验证摆放。
  默认随机模式会在开局重新摆放这些物件。修改随机布局规则时看 `coop_layout.gd`。
- **玩法**先用检查器调数值。搜寻和通关目标看 `Game`，警戒衰减看 `Alert`，巡逻和感知看母鸡，追赶与撤退看农夫。
  遇到随机地图问题，交接时附上 `Round seed` 和复现步骤。
- **界面和美术**在 `.tscn` 改排版与图形，在 `en.po` 同步英文。修改箱子或角色尺寸后，
  和玩法组一起验收碰撞、遮挡和寻路。
- **提交前**用 `git status --short` 确认主场景引用的 `scenes/` 和 `assets/` 文件、配套元数据和文档都已纳入版本控制，
  并将 `.vs/`、构建产物与凭据留在本机。让组员从干净检出导入 `project.godot`，按 **F5** 运行并复现一次改动。
