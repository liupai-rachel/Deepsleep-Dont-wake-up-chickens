# Night Coop

[简体中文](README.md)

## About the game

Night Coop is a single-player, top-down stealth game. Sneak into a chicken coop at night and search nests while the hens look away. You have **120 seconds to collect at least eight eggs and escape through the south exit**. One more search might get you the last egg, or give the farmer time to find you.

- **Choose a route and search.** Teal nests contain 1–2 eggs and take about 1.3 seconds per egg; amber nests contain 3–4 and take about 2.2 seconds per egg. Ranges are visible, exact stock is hidden. Small nests sit near cover; rich nests lie in the northern patrol zone. At least one rich nest is needed to meet the goal. Hold **E** to search; release to cancel unfinished progress.
- **Hide and distract.** Hens alarm immediately when they see the player. Use cover to break sight. Cover also blocks search noise. Start with two feed charges; tap **E** to collect more. Hold **Q** and aim with the mouse, release to throw, or right-click to cancel. Red destinations are blocked. Eating distracts a hen for about six seconds and suppresses its alarms.
- **Manage alert and escape.** Alert rises immediately when a hen sees the player or hears nearby unblocked search noise. At **60** alert, the farmer enters from the north. If he loses sight of you, he checks your last known position. Hide and stop searching to let alert fall. Once you have enough eggs, tap **E** at the south exit. Getting caught or running out of time ends the round.
- **Pixel coop and bilingual UI.** The default authored level combines golden paving, blue night scenery, stacked crate-and-hay cover, and teal-roofed nests. The round seed still drives nest inventories and patrol variation. Disable Layout > Use Fixed Layout to restore seeded layouts. You can switch between Simplified Chinese and English on the start, pause, and results screens.

## Project architecture

**Godot 4.5.1 Standard (matching export templates) · GDScript · Compatibility renderer · 960×540**

[project.godot](project.godot) holds the project settings and points to [game.tscn](game.tscn). The main scene brings the map, actors, and interface together. Each module handles its own rules.

| Module | Entry point and responsibilities |
| --- | --- |
| Round flow | [game.gd](game.gd) manages the round seed, timer, searching, farmer arrival, outcomes, and restarts. |
| Layout and navigation | [coop_layout.gd](scenes/coop_layout.gd) generates and validates layouts and builds the navigation mesh. If the generator runs out of attempts, it uses a validated fixed map. [coop_navigation.gd](scenes/coop_navigation.gd) routes the farmer and hens following bait around obstacles. |
| Actors and alert | The [player](scenes/player.gd) handles movement and facing. [Hens](scenes/chicken.gd) handle patrols, perception, and feeding. The [farmer](scenes/farmer.gd) chases, searches, and retreats. [alert.gd](scenes/alert.gd) tracks alert gain and decay. |
| Nests and feed | [nest.gd](scenes/nest.gd) tracks each nest’s inventory and state. [feed_field.gd](scenes/feed_field.gd) handles feed pickups, inventory, and throw validation. |
| Interface and feedback | [round_hud.tscn](scenes/round_hud.tscn) defines the UI layout, and [round_hud.gd](scenes/round_hud.gd) updates status and switches languages. [en.po](assets/i18n/en.po) contains the English translations, and [round_audio.tscn](scenes/round_audio.tscn) binds the audio cues. |

`scenes/` contains editable scenes and behavior scripts. `assets/` contains original artwork and audio, the UI font, and translations. The UI font is a subset of Noto Sans SC under the [SIL Open Font License](assets/fonts/OFL.txt).

See the [project file guide in Chinese](PROJECT_GUIDE.md) for a file-by-file breakdown.
