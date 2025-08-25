<p align="center">
  <img src="https://github.com/user-attachments/assets/f6aa7019-a242-4d76-8735-893f8c4dd0ba" />
</p>

# UFO 50 Save Tool
(Windows only)

My partner and I were playing on the same account on the couch, when they started playing on their own I wanted to get them their Divers save, ended up making this.

## Features
- Export specific games to a `.ufodisk` file
- Import `.ufodisk` to your save by dropping them on the .exe
- Delete specific game save data to put the dust back on your disks
- Copy specific game saves from any slot to another
- Backups your saves before any copy/export/import
- Export/Import Block Koala custom levels, edit them in plain text, validate authenticity on import
- View save contents, custom levels, garden/gold/cherry requirements, and more!

## Example Commands
**Save files**
```rb
# Copy Barbuta and Mooncat save from save file 1 to save file 2
copy -slot 1 -to 2 -games 1,13

# Export game saves from Save File 1, Divers, to a shareable file
export -slot 1 -games 27 --output disk_for_my_friend

# View playtime + Gift/Gold/Cherry status of save file 1
view -slot 1

# Delete game save for slot (making it dusty again)
delete -slot 1 -games 15

# See the requirements for unlocking the Garden Gift, Gold Disk, Cherry Disk, & Dark Cherry Disk (fan-made mod).
goals -games 25,42,45
```
**Block Koala**
```rb
# View custom level slots in save file 1
view -slot 1 -bk

# View custom level code for save file 1, slot 51
view -slot 1 -bk 51

# Export custom levels to shareable file, in plaintext for editing.
export -slot 1 -bk 51,52,53 --output my_block_koala_custom_levels
```
**Importing**
```rb
# Drop a `.ufodisk` file on `ufo-st.exe` and it will guide you
# Alternatively run `./ufo-st.exe PATH_TO_UFODISK` in a terminal of your choice.
```

## Installation
Go to [Releases](https://github.com/rowancodes/ufo-50-st/releases) and download + run the exe. It should automatically detect your save files.

Alternatively: 
1. [install Ruby 3.2+](https://rubyinstaller.org/downloads/)
2. Clone this repo
3. `ruby .\ufo_st.rb` in your terminal of choice. `ruby .\ufo_st.rb PATH_TO_UFODISK` for importing a file.
