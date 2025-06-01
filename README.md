# Room-Training-TMC
_Individual room trainer Lua script for the any% category of The Minish Cap._

## Setup :
_prerequisites_ : You have a Bizhawk folder from which you launch the Bizhawk emulator, everything that is described here takes place inside this folder.
* create an empty (text) file named `room_pb.txt` in the Lua folder
* put `room_training.lua`, `roomnames.lua`, `orderedrooms.lua` and `anypercent_savestates.lua` inside the Lua folder
* run the script `room_training.lua` from the emulator's interface

## How to create a Room Trainer for your own category ?
* make sure you include every room your route goes through by modifying the `excel_read` file accordingly and running it (for example, I excluded dev rooms in the `excel_read` python file but firerod% goes through them)
* record a movie or create a TAS of your route
* play the movie/TAS while running the `find_all_rooms.lua` script in the background, this will create custom `orderedrooms.lua` and `savestates.lua` files
* follow the steps in **Setup** again

-----------------------------------------------------------------

_`room_training.lua` is the main Lua script that you run on the Bizhawk emulator while playing TMC._

### excel_read file:
python program used to convert the data stored in the excel file (available at this link https://drive.google.com/drive/u/0/folders/1hvEhcaUQvcJ1vUw5QWFTk7_La_ELKD87) registering every room and area to their respective memory addresses into a Lua module that can be used by the `room_training.lua` main file


### find_all_rooms file:
Lua script that is supposed to run during a movie playback of a full run of the game for some category (here we have any%) and saves data according to every room (including multiples) entered throughout the game in the `savestates.lua` file, this data is used to replace more memory_intensive savestates by `room_training.lua`


### room_training file:
Lua script that displays an interface on Bizhawk letting the user choose rooms found in the any% route and load them on the emulator, you can see the time taken on each room, you can practice a room individually in a loop, and you can enable the shuffling of the rng value at the beginning of each room as to not get the same enemy patterns everytime


### roomnames file:
Lua module used in `room_training.lua` &mdash; and `find_all_rooms.lua`, the latter being for the sake of creating the `orderedrooms` and `savestates` Lua modules &mdash; creating two tables used to match memory values to room & area names, so the drop down menus on the interface are actually decipherable

### orderedrooms file:
Lua module used by the last drop down menu created in `room_training.lua` used for clarity since it shows an ordered list of all the rooms visited during the any% route, you can load them individually

### savestates file:
contains data from the game's memory at different points of a speedrun route, includes flag data (EWRAM : `0x2A60` - `0x2EC2`), some EWRAM data, necessary IWRAM data (like room & area, layer, coordinates, etc), and finally goals obtained by comparing changes in flags ; IWRAM data is structured by byte size (1 byte, 2 bytes, or 4 bytes) as specified in the google docs at https://docs.google.com/spreadsheets/d/11Ve770jjf7Y1dgf0kqWKlCjBpaNyw0XBkp-ayxeXJvg

### anypercent_lotad.bk2:
Bizhawk movie file used in tandem with the `find_all_rooms.lua` script that executes a full any% run of The Minish Cap in an hour thirty at normal speed and goes through every expected room from the octo clip route of the any% category
