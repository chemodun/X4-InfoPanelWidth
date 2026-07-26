# Info Panel Width

Adds an Options menu slider to configure the width of the Map screen's Information Panels (also affects the Player Info, Diplomacy, Crafting and Transaction Log menus, which share the same value)

## Features

- By default, the game limits this width to at most 30% of your screen.
- This mod turns that old limit into the slider's new *dynamic minimum* and fixed *maximum* from menu width instead: the panels can now be made wider or narrower than the game ever allowed on their own, directly from Options > Game Settings (right after the "UI Scale" option).
- Because the game reuses this same width setting in a few other places, the slider affects those too, as a side effect:
  - The **Player Info** and **Diplomacy** screens' main panel (on the left side of the screen).
  - The **Transaction Log** screen's main panel (at the left edge of the screen).
  - The **Crafting** screen's whole window (centered on the screen).
  - The small **player status text** (your name, credits owed, current sector, play time) shown in the top-left corner of the Player Info, Diplomacy, Docked, Help, and Map screens - here there's no panel to resize, it just changes how much room that text has before it gets shortened.

## Limitations

- Take into account that most Information Panels have their own built-in minimum width limits and won't shrink past that point even if you set the slider all the way down.

## Requirements

- `X4: Foundations` 9.00 or newer.
- `kuertee UI Extensions and HUD`, to hook into the Options menu. Version `9.00` and upper is required.

## Installation

Not yet published.

## Usage

Open the in-game Options menu, go to Game Settings, and use the new slider (right below "UI Scale") to set the width of the Map screen's Information Panels (and the other screens that share the same setting). Default: 30% of your screen width, the same as the game's original setting.

## Credits

- Author: Chem O`Dun, on [Nexus Mods](https://next.nexusmods.com/profile/ChemODun/mods?gameId=2659) and [Steam Workshop](https://steamcommunity.com/id/chemodun/myworkshopfiles/?appid=392160)
- *"X4: Foundations"* is a trademark of [Egosoft](https://www.egosoft.com).

## Acknowledgements

- [EGOSOFT](https://www.egosoft.com) - for the X series.
- [kuertee](https://next.nexusmods.com/profile/kuertee?gameId=2659) - for the UI Extensions and HUD framework this mod hooks into.

## Changelog

### [1.01] - 2026-07-26

- Added
  - Initial public release.
