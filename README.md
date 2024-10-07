<p align="center">
  <img src="https://github.com/user-attachments/assets/f6aa7019-a242-4d76-8735-893f8c4dd0ba" />
</p>

# UFO 50 Save Tool
(Windows only)

My partner and I were playing on the same account on the couch, when they started playing on their own I wanted to get them their Divers save, ended up making this.

## Features
- Export specific games to a `.ufodisk` file
- Import `.ufodisk` to your save by dropping them on the .exe
- Export/Import Block Koala custom levels, edit them in plain text, validate authenticity on import
- Copy specific game saves from any slot to another
- Backups your saves before any copy/export/import

## Example Commands
**Save files**
```rb
# Copy Barbuta and Mooncat save from save file 1 to save file 2
copy -slot 1 -to 2 -games 1,13

# Export game saves from Save File 1, #1->#10 into a shareable file
export -slot 1 -games 1,2,3,4,5,6,7,8,9,10 --output my_cool_disk

# View playtime + Gift/Gold/Cherry status of save file 1
view -slot 1
```
**Block Koala**
```rb
# View custom level slots in save file 1
view -slot 1 -bk

# View custom level code for save file 1, slot 51
view -slot 1 -bk 51

# Export custom levels to shareable
export -slot 1 -bk 51,52,53 --output my_block_koala_custom_levels
```
**Importing**
```rb
# Drop a `.ufodisk` file on `ufo-st.exe` and it will guide you
```

## Installation
Go to Releases and download + run the exe. It should automatically detect your save files.

![image](https://github.com/user-attachments/assets/4bb96da5-1dd7-4d13-8937-665774ea4657)
