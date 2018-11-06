![BattleFriends Prop Hunt Logo](https://github.com/zach-r-d/battlefriends_prop_hunt/raw/master/gamemodes/battlefriends_prop_hunt/logo.png "BattleFriends Prop Hunt Logo")

# BattleFriends Prop Hunt

This is a customization of [Prop Hunt: Enhanced v15 Rev. G](https://github.com/Vinzuerio/ph-enhanced/tree/v15-g) made for BattleFriends.

## Player instructions

You shouldn't need to do anything. Just join a server running this gamemode, and it should automatically send you everything you need.

## Server-host instructions

### Listen server (i.e. starting a server from within the game itself)

Install BattleFriends Prop Hunt via [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=1555099832).

You should now be able to select the gamemode in the gamemode selector on the main menu.

### Dedicated server (i.e. srcds)

Haven't tried that yet. Good luck and let me know how it goes.

## Developer instructions

### Setup

1. `cd` into `\steamapps\common\GarrysMod\garrysmod\addons\`.
2. Delete `battlefriends_prop_hunt.gma` if it exists to prevent any potential conflicts with the folder you're about to create.
3. Clone this repo. The checkout should live in a `battlefriends_prop_hunt` folder in the `addons` folder.
4. Develop away.

### Tools

GMod uses its own flavor of Lua, so don't be surprised if your favorite text editor barfs when trying to use normal Lua syntax highlighting. Notepad++ with the Gmod Lua Highlighter addon installed works well.

### Random things to beware of

* Make sure you don't break packaging when adding new files
  * GMad.exe is extremely picky about what files can be included in the .gma
    * Filenames must be all lowercase
    * Files must match an entry in [the whitelist](https://github.com/garrynewman/gmad/blob/master/include/AddonWhiteList.h)
  * Files *not* meant to go in the .gma must be have appropriate entries created in the `ignore` section of `addon.json`.
  * Run `package.sh --test` at any time to ensure packaging still works.
* Sound file formats
  * Taunts should be .wav files since .mp3 files seem to not have their durations calculated correctly.
  * For other sound files, might as well do .mp3 to keep file size down.

