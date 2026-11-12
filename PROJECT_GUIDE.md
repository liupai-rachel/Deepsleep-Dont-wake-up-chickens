# 项目文件说明

当前游戏为“捡蛋冲分版”，入口 `project.godot` → `scenes/arcade/game.tscn`，使用 Godot 4.5.1 Standard。

| 文件 | 职责 |
| --- | --- |
| `scenes/arcade/game.gd` | 120 秒对局、右键选取、连捡计分、随机补蛋、黄金鸡事件、暂停和结算；连接菜单与商店。 |
| `scenes/arcade/world.gd` | 四关真实场地尺寸、边界和障碍碰撞、随机鸡窝／蛋的有效落点；铺设像素地面和鸡舍背景。 |
| `scenes/arcade/egg.gd` | 普通蛋、金蛋的像素图形和轻微浮动，不含接近自动拾取逻辑。 |
| `scenes/arcade/nest.gd` | 每次点击立即取蛋，直接绘制当前库存，取空后随机补货。 |
| `scenes/arcade/hen.gd` | 普通／黄金鸡的游走与产蛋。没有警戒、怀疑和抓捕。 |
| `scenes/arcade/effect.gd` | 鸡蛋飞入背包、跳分反馈。分数在点击时立即结算，不等待飞行动画。 |
| `scenes/arcade/profile.gd` | 钱币、四关最高分、解锁关卡和三项五级升级；校验损坏存档与购买条件。网页用 localStorage，桌面用 user:// 文件。 |
| `scenes/arcade/ui.gd` | 中英菜单、关卡选择、商店、暂停、结算和游戏 HUD。 |
| `scenes/player.*`、`character_art.gd` | 复用玩家移动与角色像素图集，保持脚底定位。 |
| `scenes/prop_art.gd`、`crate.tscn` | 等比显示鸡窝／木箱素材，复用掩体碰撞。 |
| `assets/art/` | 角色、鸡舍、道具图集与透明裁切／背景投影 shader。 |
| `tests/arcade_flow.gd` | 当前玩法回归验证。测试使用独立存档，不影响正常进度，并排除在导出之外。 |

## 关键规则

只有右键按下事件会收集；按住鼠标、左键和角色靠近都不会自动拿蛋。连收升级仅扩大一次手动点击的作用范围。

鸡窝每次点击扣一枚，库存立刻可见地减少；随机补货不直接增加玩家分数。地面刷新有数量上限，金蛋在普通蛋铺满时仍有出现机会。

四关场地边长分别为基础的 1、1.2、1.4、1.6 倍，镜头保持等比例；每关新增障碍和鸡窝，地面采用重复纹理使空间扩展可见。

一局只结算一次；未完成时退出菜单不奖励、不解锁。钱币、升级和最高分保存在当前浏览器，清除站点数据会清除进度。保存不可用时菜单会提示。

## 验证

`godot --headless --path . --fixed-fps 60 --script tests/arcade_flow.gd`

覆盖手动鼠标拾取、不会靠近误捡、可见库存、补货／补蛋、暂停计时、结算防重复、购买与读取存档、四关增长、金蛋与连收升级。

修改后执行无界面导入和 Web 导出，并检查实际渲染与鼠标输入。保持 `.godot/`、`build/` 和凭据不入库。

## 旧玩法

原 `game.gd`、`game.tscn`、`coop_layout.gd`、`chicken.gd`、`farmer.gd` 等保留为旧潜行原型，已不再是启动入口。`tests/gameplay_flow.gd` 仅用于该原型，当前验收请运行 `tests/arcade_flow.gd`。

开发阶段和下一步见 `DEVELOPMENT_PLAN.md`。字体许可见 `assets/fonts/OFL.txt` 与 `PressStart2P-OFL.txt`。
