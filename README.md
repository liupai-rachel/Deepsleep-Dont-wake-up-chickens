# 夜访鸡舍 · Night Coop

[简体中文](#中文) · [English](#english) · [项目文件说明 / Project file guide (Chinese)](PROJECT_GUIDE.md) · [导出命令 / Export commands](#export-commands)

## 中文

在夜晚潜入随机生成的鸡舍，观察母鸡巡逻，搜集至少 **6 枚鸡蛋**，并在
**120 秒**内从南侧绿色入口撤离。墙壁和木箱能遮挡视线，饲料能暂时引开母鸡。

### 启动与操作

用 **Godot 4.5.1 Standard** 导入 `project.godot`，按 **F5**，再点击
**开始行动**。项目使用 GDScript 和 Compatibility 渲染器。导出需要安装
同版本的 Standard 导出模板。游戏默认显示简体中文，在开始、暂停或结算界面
点击 **English** 或 **中文** 可立即切换。切换不影响本局，重新开始会保留当前语言。

| 按键 | 操作 |
| --- | --- |
| WASD / 方向键 | 移动及改变朝向 |
| 按住 E | 在鸟巢旁搜寻，每 2 秒取一枚蛋。松开会取消当前进度 |
| 轻按 E | 拾取附近的绿袋。达标后，在南侧绿色入口撤离 |
| Q | 朝前方投放一份饲料。落点不合法时保留库存 |
| Esc / 暂停按钮 | 暂停、继续或重新开始 |

每个鸟巢有 1～3 枚蛋，数量在开局时确定。巢上的 `?`、`+` 和 `X`
分别表示未搜寻、仍可搜寻和已搜空。搜寻声能隔着掩体传播。HUD 会分别
提示母鸡看见玩家和搜寻声引发鸣叫。

警戒达到 **60** 时，农夫在预警后从北侧入场。躲到掩体后并停止搜寻，
连续 **3 秒**没有被看见或引发鸣叫，警戒会开始下降。农夫会调查最后
目击点，搜寻后在警戒降至 **30** 或以下时撤退。被抓或超时均会结算，
结果页显示鸡蛋数、用时和结算原因。

### 复现与队友验收

编辑器运行时，「输出」面板会打印 `Round seed`。在 `game.tscn` 中选中
`Game`，启用 **Round Seed → Use Fixed Seed**，将数值填入 **Fixed Seed**，
即可复现地图、库存和巡逻。也可以在 `Layout` 启用 **Use Fixed Layout**
使用原地图，或将 **Generation Attempts** 设为 0 验证自动回退。

1. 用固定种子 **2** 观察巡逻，按住 E 搜寻后中途松开，确认未获得蛋。
   搜空一个巢后继续按 E，确认总数不会再增加。
2. 在无遮拦处触发警戒 60，观察预警和唯一的农夫入场。绕到木箱另一侧，
   沿南侧通道拉开距离，停止搜寻，确认警戒下降。达标后在南侧按 E 撤离。
3. 分别让倒计时耗尽和让农夫在无遮挡处抓到玩家，确认失败原因不同。
   搜寻时按 Esc，确认计时、动作和进度冻结。暂停时松开 E，再按住 E
   恢复，确认搜寻重新计时。连续重开，确认警戒、库存、诱饵、农夫和结算全部复位。
4. 空手按 Q，再拾取饲料朝墙按 Q，确认两次均有提示且库存不扣减。
   关闭固定种子，重开几局，检查鸟巢、饲料和入口都可到达。
5. 在开始界面切换到 English，确认操作说明和按钮更新。开局后暂停并切回中文，
   确认鸡蛋数和倒计时保持原值。结算时再次切换，检查原因和用时，并确认重开保留当前语言。

### 素材与发布

场景图形、地面、院子和灯光 SVG 均为项目原创。六段 WAV 提示音由项目合成。
随项目分发的 UI 字体为 Noto Sans SC 子集，采用 [SIL 开源字体许可](assets/fonts/OFL.txt)。

按[导出命令](#export-commands)可在本地构建 Windows、Web 和 Linux 版本。GitHub
Actions 也会构建三平台并上传 `game-exports`。发布时，在已测试的提交上推送
`vMAJOR.MINOR.PATCH` 标签。构建成功后，GitHub Releases 会生成 `web.zip`、
`linux.zip` 和 `windows.zip`。手动运行工作流可以生成 `release-preview` 供试玩。
每次正式发布使用新标签，并确保工作流的 `GITHUB_TOKEN` 拥有仓库内容写入权限。
公共仓库的发布对外公开。桌面版本未签名，移动端需要单独的 SDK、配置和签名。

在 Codex 云环境中连接 GitHub 并选择仓库，用 `.codex/setup.sh` 和下方 Linux
命令配置、构建并保存环境。Codex 云环境与 GitHub Actions 运行器各自独立。
如需发布 Web 版到 Cloudflare Workers，在 GitHub Actions secrets 中设置
`CLOUDFLARE_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID`，在 variables 中设置
`CLOUDFLARE_WORKER_NAME`。若使用保护规则，创建 `production` 环境。
手动运行 **Deploy web (manual)** 后，从日志打开部署链接。凭据保存在 GitHub
Secrets 中，构建目录 `build/` 已被 Git 忽略。

## English

Sneak into a randomly generated chicken coop at night. Collect at least **6 eggs**
and escape through the green south exit within **120 seconds**. Walls and crates
block sight, and feed can briefly distract hens.

### Launch and controls

Import `project.godot` in **Godot 4.5.1 Standard**, press **F5**, and click **Start**.
The project uses GDScript and the Compatibility renderer. Install the matching
Standard export templates before exporting.

The game opens in Simplified Chinese. Click **English** or **中文** on the start,
pause, or results screen to switch immediately. Switching preserves the current
round, and restarting keeps the selected language.

| Input | Action |
| --- | --- |
| WASD / Arrow keys | Move and change facing direction |
| Hold E | Search a nearby nest. Take one egg every 2 seconds. Releasing E cancels current progress |
| Tap E | Pick up a nearby green feed bag, or use the green south exit once you have enough eggs |
| Q | Throw one portion of feed ahead. An invalid landing spot costs no feed |
| Esc / Pause button | Pause, resume, or restart |

Each nest starts with 1–3 eggs. Its inventory is set for the round and stays
hidden. The `?`, `+`, and `X` markers indicate an unsearched nest, a nest you
can keep searching, and an empty nest. Search noise can travel through cover.
The HUD distinguishes being seen by a hen from a hen clucking after hearing a search.

At **60** alert, a warning appears and the farmer enters from the north. Hide
behind cover and stop searching. Alert starts falling after **3 seconds** without
a sighting or cluck. The farmer investigates your last known location and leaves
after searching if alert has fallen to **30** or below. Getting caught or running
out of time ends the round. The results show the egg count, elapsed time, and outcome.

### Reproduce a round and playtest

In the editor, the Output panel prints `Round seed`. To reproduce the layout,
egg inventory, and patrols, select `Game` in `game.tscn`, enable **Round Seed →
Use Fixed Seed**, and enter the value in **Fixed Seed**. Enable **Use Fixed Layout**
on `Layout` to use the original map, or set **Generation Attempts** to 0 to test
the automatic fallback.

1. Use seed **2**. Watch the patrols, hold E near a nest, then release it before
   the search completes. Confirm you gained no egg. Empty a nest and keep
   holding E to check that the count stops increasing.
2. Raise alert to 60 in the open. Watch for the warning and a single farmer
   entering. Break line of sight behind a crate, take the south corridor, and
   stop searching so alert can fall. After meeting the egg goal, press E at
   the south exit to win.
3. Run out of time and get caught in separate rounds to check both failure reasons.
   Pause while searching and confirm the timer, movement, and progress freeze.
   Release E while paused, then hold it again and resume to check that search
   progress starts over. Restart several times and check that alert, inventory,
   bait, the farmer, and the results all reset.
4. Press Q with no feed. Pick up a bag and press Q while facing a wall. Check
   both notices and confirm neither throw consumes feed. Disable the fixed seed
   and try several layouts to check that the nests, feed, and exit are reachable.
5. Switch to English from the start screen and check the controls and buttons.
   Pause during a round and switch to Chinese. Check that the egg count and
   timer are preserved. Switch again on the results screen and check the outcome,
   elapsed time, and language after restarting.

### Assets and releases

The scene shapes, floor, yard and lamp SVGs are original project artwork.
The six WAV cues are original synthesized sounds made for this project.
The bundled UI font is a subset of Noto Sans SC, distributed with
the [SIL Open Font License](assets/fonts/OFL.txt).

The GitHub Actions build runs the commands below and uploads `game-exports`.
To publish a tested build, push a new `vMAJOR.MINOR.PATCH` tag. After a successful
build, find `web.zip`, `linux.zip`, and `windows.zip` under **Releases**. Run the
workflow manually to download a `release-preview` artifact for playtesting.
Keep Actions enabled and allow the workflow's `GITHUB_TOKEN` to write repository
contents. Releases in public repositories are public. Desktop builds are
unsigned. Mobile exports require separate SDKs, configuration, and signing.

In Codex Cloud, connect GitHub and choose your repository. Use `.codex/setup.sh`
and the Linux commands below to set up, build, and save the environment. The
Codex Cloud environment and GitHub Actions runner are separate.
For optional Cloudflare Workers deployment, add `CLOUDFLARE_API_TOKEN` and
`CLOUDFLARE_ACCOUNT_ID` as GitHub Actions secrets, and set the
`CLOUDFLARE_WORKER_NAME` variable. Create a `production` environment if using
protection rules. Run **Deploy web (manual)** and open the deployment URL from
the log. Store credentials in GitHub Secrets. Git ignores `build/`.

<a id="export-commands"></a>

## 导出命令 · Export commands

在项目根目录运行。Windows 下把 `$godot` 改为实际安装路径。

Run from the project root. On Windows, point `$godot` to your editor executable.

```powershell
$godot = 'E:\Godot\Godot_v4.5.1-stable_win64_console.exe'
New-Item -ItemType Directory -Force build/web,build/linux,build/windows | Out-Null
if (-not (Test-Path build/.gdignore)) { New-Item -ItemType File build/.gdignore | Out-Null }
& $godot --headless --path . --import
& $godot --headless --path . --export-release Web build/web/index.html
& $godot --headless --path . --export-release Linux build/linux/game.x86_64
& $godot --headless --path . --export-release Windows build/windows/game.exe
```

在 Linux x86_64 上，`.codex/setup.sh` 下载官方编辑器和模板，并执行无界面导入。
运行前需要 `curl`、`unzip`、网络连接和数 GB 的可用空间。

On Linux x86_64, `.codex/setup.sh` downloads the official editor and templates
and runs a headless import. It requires `curl`, `unzip`, an internet connection,
and several GB of free space.

```bash
.codex/setup.sh
GODOT="$HOME/.cache/sd5913-godot-4.5.1/godot"
mkdir -p build/web build/linux build/windows && touch build/.gdignore
"$GODOT" --headless --path . --export-release Web build/web/index.html
"$GODOT" --headless --path . --export-release Linux build/linux/game.x86_64
"$GODOT" --headless --path . --export-release Windows build/windows/game.exe
```

| 平台 / Platform | 启动文件 / Entry point |
| --- | --- |
| Windows | `build/windows/game.exe` |
| Web | `build/web/index.html` |
| Linux x86_64 | `build/linux/game.x86_64` |

Windows 和 Linux 版本需要与同目录的 `game.pck` 一起分发。Web 版保留同目录
的全部文件，通过 HTTP 启动，打开 [本地试玩页](http://localhost:8000/)。
导出的版本也可使用上面的试玩步骤。

Keep the Windows and Linux executables next to their respective `game.pck`
files. Serve all files in the Web output over HTTP and open the [local playtest page](http://localhost:8000/).
Use the same playtest steps for exported builds.

```bash
python -m http.server 8000 --directory build/web
```

[Godot 导出文档 / Godot export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/index.html)
