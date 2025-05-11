# Room-Training-TMC
_Individual room trainer Lua script for the any% category of The Minish Cap._

## Setup :
_prerequisites_ : You have a Bizhawk folder from which you launch the Bizhawk emulator, everything that is described here takes place inside this folder.
* create a folder inside the State folder named `ROOMTRAINERFOLDER`
* put the contents of each ROOMTRAINERFOLDER folders 1 through 4 inside the eponym folder you just created
* an alternative to downloading the 4 folders (which are, in total, just short of 100 Mo) is to run the `find_all_rooms.lua` script while playing the movie `anypercent_lotad.bk2` on your emulator &mdash; and commenting the part of the script where it creates another copy of `orderedrooms.lua` to avoid redundancy
* put `room_training.lua`, `roomnames.lua` and `orderedrooms.lua` inside the Lua folder
* run the script `room_training.lua` from the emulator's interface

-----------------------------------------------------------------

_`room_training.lua` is the main Lua script that you run on the Bizhawk emulator while playing TMC, while having all your Lua files in the Lua folder of your Bizhawk folder and having created a `ROOMTRAINERFOLDER` folder in the State folder of Bizhawk, it helps selecting rooms to train on and enabling nice features so that training becomes easier._

### excel_read file:
python program used to convert the data stored in the excel file (available at this link https://drive.google.com/drive/u/0/folders/1hvEhcaUQvcJ1vUw5QWFTk7_La_ELKD87) registering every room and area to their respective memory addresses into a Lua module that can be used by the `room_training.lua` main file


### find_all_rooms file:
Lua script that is supposed to run during a movie playback of a full run of the game for some category (here we have any%) and saves savestates according to every room (including multiples) entered throughout the game in the `ROOMTRAINERFOLDER` folder that you have to create beforehand in the State folder of Bizhawk, these savestates are used by `room_training.lua`


### room_training file:
Lua script that displays an interface on Bizhawk letting the user choose rooms found in the any% route according to the savestates saved in `find_all_rooms.lua` and load them on the emulator, you can see the time taken on each room, you can practice a room individually in a loop, and you can enable the shuffling of the rng value at the beginning of each room as to not get the same enemy patterns everytime


### roomnames file:
Lua module used in `room_training.lua` &mdash; and `find_all_rooms.lua`, the latter being for the sake of creating the `orderedrooms` Lua module &mdash; creating two tables used to match memory values to room & area names, so the drop down menus on the interface are actually decipherable

### orderedrooms file:
Lua module used by the last drop down menu created in `room_training.lua` used for clarity since it shows an ordered list of all the rooms visited during the any% route, you can load them individually
