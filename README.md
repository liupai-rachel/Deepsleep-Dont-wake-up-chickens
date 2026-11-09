# 夜访鸡舍 · Night Coop

**一款单人俯视角潜行游戏。趁母鸡转身时搜蛋，在农夫抓到你之前溜出鸡舍。**

**A single-player, top-down stealth game. Search nests while the hens look away, then slip out before the farmer catches you.**

[中文](#中文) · [English](#english) · [开发与验收 / Playtesting](#playtest) · [导出 / Exports](#export-commands) · [项目结构 / Project guide](PROJECT_GUIDE.md)

## 中文

### 一局怎么玩

你的目标是 **120 秒内搜集至少 6 枚鸡蛋，并从南侧绿色入口撤离**。每局的鸡舍布局和鸟巢库存由种子决定。同一个巢可能只够搜一次，也可能值得再冒一次险。

1. **先看母鸡往哪走。** 视野扇形会随母鸡转向，墙壁和木箱可以挡住视线。捡到饲料后，可以把它扔到别处，暂时引开附近的母鸡。
2. **决定要不要再搜一次。** 靠近鸟巢，按住 **E** 两秒取一枚蛋。每个巢有 1～3 枚蛋，剩余数量隐藏。巢上的 `?`、`+`、`X` 分别表示未搜寻、仍可搜寻、已搜空。搜寻时不能移动，松手会清除本次未完成的进度。
3. **听到鸣叫就留意警戒。** 母鸡既能看见你，也能隔着木箱听到搜寻声。HUD 会区分这两种情况。警戒达到 **60**，农夫会在短暂预警后从北侧入场。他失去视线后会去最后目击点搜寻。躲到掩体后停止搜寻，连续 **3 秒**没有被看见或引发鸣叫，警戒才开始下降。农夫搜寻后会在警戒降至 **30** 或以下时撤退。
4. **带着鸡蛋回来。** 达标后，在南侧绿色入口轻按 **E** 撤离。超时或被抓都会结束本局，结算页会显示鸡蛋数、用时和结果。

### 快速试玩

1. 用 **Godot 4.5.1 Standard** 导入 [project.godot](project.godot)。
2. 按 **F5**，在开始界面点击 **开始行动**。

游戏默认使用简体中文。在开始、暂停或结算界面点击 **English** 或 **中文** 可立即切换，本局进度会保留。重开也会保留当前语言。

| 按键 | 操作 |
| --- | --- |
| **WASD** / **方向键** | 移动与转向 |
| **按住 E** | 搜寻附近的鸟巢 |
| **轻按 E** | 拾取附近的绿色饲料袋，或在达标后撤离 |
| **Q** | 朝前投放一份饲料。落点不合法时保留库存 |
| **Esc** / **暂停按钮** | 暂停或继续。暂停菜单也可以重开 |

## English

### How a round plays

**Collect at least 6 eggs in 120 seconds and escape through the green south exit.** The round seed determines the layout and how many eggs each nest contains. One nest might be worth a single search. Another might tempt you to stay a little longer.

1. **Watch the hens.** Their vision cones turn with them, and walls and crates block sight. Pick up feed and throw it nearby to distract a hen long enough to slip past.
2. **Decide whether to search again.** Hold **E** for two seconds near a nest to take one egg. Each nest holds 1–3 eggs, and the remaining count is hidden. The `?`, `+`, and `X` markers mean unsearched, still searchable, and empty. You stand still while searching. Letting go of **E** cancels the current search.
3. **Listen for clucks.** Hens can see you or hear a search through cover. The HUD tells you which happened. At **60** alert, a warning appears and the farmer enters from the north. If he loses sight of you, he searches your last known position. Hide and stop searching. Alert starts falling after **3 seconds** without a sighting or cluck. The farmer retreats after searching once alert falls to **30** or below.
4. **Get out with the eggs.** Once you have enough eggs, tap **E** at the green south exit. The round ends if the farmer catches you or time runs out. The results screen shows the egg count, elapsed time, and outcome.

### Quick start

1. Import [project.godot](project.godot) in **Godot 4.5.1 Standard**.
2. Press **F5**, click **English**, then click **Start**.

The game opens in Simplified Chinese. You can switch languages from the start, pause, or results screen. Switching keeps your round progress, and restarting keeps the selected language.

| Input | Action |
| --- | --- |
| **WASD** / **Arrow keys** | Move and turn |
| **Hold E** | Search a nearby nest |
| **Tap E** | Pick up a nearby green feed bag, or exit once you have enough eggs |
| **Q** | Throw one portion of feed ahead. An invalid landing spot costs no feed |
| **Esc** / **Pause button** | Pause or resume. You can also restart from the pause menu |

<a id="playtest"></a>

## 开发与验收 · Development and playtesting

项目使用 **Godot 4.5.1 Standard**、**GDScript** 和 **Compatibility** 渲染器。各场景、脚本和素材的职责见 [项目文件说明](PROJECT_GUIDE.md)。

The project uses **Godot 4.5.1 Standard**, **GDScript**, and the **Compatibility** renderer. See the [project file guide in Chinese](PROJECT_GUIDE.md) for a map of the scenes, scripts, and assets.

- **复现一局 / Reproduce a round**

  从编辑器的输出面板复制 `Round seed`。打开 `game.tscn`，选中 `Game`，启用 **Round Seed → Use Fixed Seed**，在 **Fixed Seed** 填入种子。

  Copy `Round seed` from the editor’s Output panel. In `game.tscn`, select `Game`, enable **Round Seed → Use Fixed Seed**, and paste the seed into **Fixed Seed**.

- **检查固定地图 / Inspect the fixed map**

  选中 `Layout`，启用 **Use Fixed Layout**。要测试自动回退，关闭固定地图并将 **Generation Attempts** 设为 0。

  Select `Layout` and enable **Use Fixed Layout**. To test automatic fallback, turn it off and set **Generation Attempts** to 0.

<details>
<summary>队友试玩清单</summary>

1. 用固定种子 **2**。在取到蛋之前松开 **E**，确认没有得蛋。搜空一个巢后继续按 **E**，确认计数保持不变。
2. 触发警戒 **60**，确认预警后只出现一名农夫。绕到箱子后切断视线，停止搜寻并等待警戒下降。达标后到南侧按 **E** 撤离。
3. 分别测试被抓和超时，核对结算原因。搜寻时按 **Esc**，确认计时、动作和搜寻进度暂停。暂停时松开 **E**，再按住并继续，确认搜寻重新计时。连续重开，确认警戒、鸡蛋和饲料库存、诱饵、农夫及结算全部复位。
4. 空手按 **Q**，再拾取饲料朝墙投放，确认两种提示都正确，库存保持原值。关闭固定种子后重开几局，确认鸟巢、饲料与出口可达。
5. 在开始、暂停和结算页切换中英文。核对按钮、提示与结果文字，确认倒计时和鸡蛋数保留，重开沿用当前语言。

</details>

<details>
<summary>Playtest checklist</summary>

1. Use fixed seed **2**. Release **E** before the search finishes and check that you gained zero eggs. Empty a nest, then keep holding **E** and check that the count stays the same.
2. Raise alert to **60**. Check that the warning is followed by one farmer. Break line of sight behind a crate, stop searching, and wait for alert to fall. Reach the egg goal and press **E** at the south exit to escape.
3. Get caught and run out of time in separate rounds to check both results. Pause while searching and check that time, movement, and search progress freeze. Release **E** while paused, hold it again, then resume and check that the search starts over. Restart several times and check that alert, egg and feed inventory, bait, the farmer, and the results reset.
4. Press **Q** with empty pockets. Pick up a bag and throw towards a wall. Check both notices and confirm the inventory stays the same. Disable the fixed seed and check that nests, feed, and the exit are reachable in several new layouts.
5. Switch languages on the start, pause, and results screens. Check buttons, prompts, and results. Confirm that time and egg counts are preserved and that the selected language carries over after restarting.

</details>

<a id="export-commands"></a>

## 导出命令 · Export commands

在项目根目录执行。Windows 使用与编辑器同版本的 **4.5.1 Standard** 导出模板，并将 `$godot` 改为本机路径。

Run from the project root. On Windows, install the matching **4.5.1 Standard** export templates and point `$godot` to your editor executable.

### Windows PowerShell

```powershell
$godot = 'C:\path\to\Godot_v4.5.1-stable_win64_console.exe'
New-Item -ItemType Directory -Force build/web,build/linux,build/windows | Out-Null
if (-not (Test-Path build/.gdignore)) { New-Item -ItemType File build/.gdignore | Out-Null }
& $godot --headless --path . --import
& $godot --headless --path . --export-release Web build/web/index.html
& $godot --headless --path . --export-release Linux build/linux/game.x86_64
& $godot --headless --path . --export-release Windows build/windows/game.exe
```

### Linux x86_64

`.codex/setup.sh` 会下载官方编辑器和模板，并执行无界面导入。需要 `curl`、`unzip`、网络和数 GB 可用空间。

`.codex/setup.sh` downloads the official editor and templates and runs a headless import. It requires `curl`, `unzip`, internet access, and several GB of free space.

```bash
.codex/setup.sh
GODOT="${XDG_CACHE_HOME:-$HOME/.cache}/sd5913-godot-4.5.1/godot"
mkdir -p build/web build/linux build/windows && touch build/.gdignore
"$GODOT" --headless --path . --export-release Web build/web/index.html
"$GODOT" --headless --path . --export-release Linux build/linux/game.x86_64
"$GODOT" --headless --path . --export-release Windows build/windows/game.exe
```

| 平台 / Platform | 启动文件 / Entry point |
| --- | --- |
| Windows | `build/windows/game.exe` |
| Linux x86_64 | `build/linux/game.x86_64` |
| Web | `build/web/index.html` |

桌面版需和同目录的 `game.pck` 一起分发。Web 版保留整个 `build/web/`，通过 HTTP 启动。

Keep each desktop executable next to its `game.pck`. Serve the entire `build/web/` directory over HTTP.

```bash
python -m http.server 8000 --directory build/web
```

[本地试玩页 / Local playtest page](http://localhost:8000/)

### 发布与部署 · Releases and deployment

<details>
<summary>GitHub Actions、Codex Cloud 与 Cloudflare</summary>

- **GitHub Actions** 会导出三平台并上传 `game-exports`。手动运行 **Check and export** 可获得 `release-preview`。推送新的 `vMAJOR.MINOR.PATCH` 标签后，构建成功会在 GitHub Releases 发布 `web.zip`、`linux.zip` 和 `windows.zip`。发布任务的 `GITHUB_TOKEN` 需要仓库内容写权限。公共仓库的发布对外公开。
- **Codex Cloud** 连接 GitHub 并选择仓库后，用 `.codex/setup.sh` 和上面的 Linux 命令配置环境与构建。Codex 云环境和 GitHub Actions 运行器各自独立。
- **Cloudflare Workers** 使用 GitHub Actions secrets `CLOUDFLARE_API_TOKEN`、`CLOUDFLARE_ACCOUNT_ID` 及变量 `CLOUDFLARE_WORKER_NAME`。部署流程使用 `production` 环境，可按需配置保护规则。手动运行 **Deploy web (manual)** 后，从日志打开部署链接。

桌面构建未签名，移动端导出需要单独的 SDK、配置和签名。凭据存放在 GitHub Secrets，`build/` 已被 Git 忽略。

</details>

<details>
<summary>GitHub Actions, Codex Cloud, and Cloudflare</summary>

- **GitHub Actions** exports all three targets and uploads `game-exports`. Run **Check and export** manually to get a `release-preview` artifact. Push a new `vMAJOR.MINOR.PATCH` tag to publish `web.zip`, `linux.zip`, and `windows.zip` under GitHub Releases after a successful build. The release job’s `GITHUB_TOKEN` needs repository contents write permission. Releases in public repositories are public.
- **Codex Cloud** uses `.codex/setup.sh` and the Linux commands above after you connect GitHub and select the repository. The Codex Cloud environment and GitHub Actions runner are separate.
- **Cloudflare Workers** uses GitHub Actions secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, plus the `CLOUDFLARE_WORKER_NAME` variable. The workflow uses the `production` environment, where you can configure protection rules. Run **Deploy web (manual)** and open the deployment URL from the log.

Desktop builds are unsigned. Mobile exports require separate SDKs, configuration, and signing. Keep credentials in GitHub Secrets. Git ignores `build/`.

</details>

[Godot 导出文档 / Godot export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/index.html)

## 素材与许可 · Assets and credits

场景图形、地板、院子和灯光 SVG 均为项目原创。六段 WAV 提示音由项目合成。UI 使用 Noto Sans SC 子集。[SIL 开源字体许可](assets/fonts/OFL.txt)

The scene artwork, floor, yard, and lamp SVGs are original to the project. The six WAV cues were synthesized for the game. The UI uses a subset of Noto Sans SC. [SIL Open Font License](assets/fonts/OFL.txt)
