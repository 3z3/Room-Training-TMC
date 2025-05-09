RMNM = require "roomnames"   -- Lua file containing tables that translate memory addresses to names
local statepath = '..\\GBA\\State\\TESTFOLDER\\'    -- append the name of a savestate file to the path for it to load properly with savestate.load()
local path = '..\\GBA\\State\\'
local temp_save = 'temporary_savestate.State'

local timer_frames = 0

local name_to_area = {}
local name_to_room = {}
local areasnames = {}

-- reads through the TESTFOLDER directory to get each savestate name in a table
local savestate_names = {}  -- [1 hex byte] (area memory value) = { [2 hex bytes] (room memory value) = rooms } (/!\ these hex values are lowercase)
for dir in io.popen([[dir "..\GBA\State\TESTFOLDER\" /b]]):lines() do   -- lists every savestate name into the savestate_names table, associating a room + area to one or more savestates
    local temp_area = string.upper(string.sub(dir,3,4))
    local temp_room = string.upper(string.sub(dir,1,4))
    if savestate_names[temp_area] == nil then   -- if a value is not assigned yet
        savestate_names[temp_area] = { [temp_room] = {dir} }
        name_to_area[RMNM.mem_to_areas(temp_area)] = temp_area
        name_to_room[RMNM.mem_to_rooms(temp_room) .. "PLUS" .. RMNM.mem_to_areas(temp_area)] = temp_room
        table.insert(areasnames,RMNM.mem_to_areas(temp_area))
    else
        if savestate_names[temp_area][temp_room] == nil then
            savestate_names[temp_area][temp_room] = {dir}
            name_to_room[RMNM.mem_to_rooms(temp_room) .. "PLUS" .. RMNM.mem_to_areas(temp_area)] = temp_room
        else
            table.insert(savestate_names[temp_area][temp_room],dir)
        end
    end
end

local function load_current_state()
    local state = forms.gettext(INDIVIDUAL_STATE_MENU)
    savestate.load(statepath .. state)
    savestate.save(path .. temp_save)
    timer_frames = 0
end

local function load_current_room()
    local area = forms.gettext(AREA_MENU)
    local room = forms.gettext(ROOM_MENU)
    local area_memory = name_to_area[area]  -- may not be a function; a table rather
    local room_memory = name_to_room[room .. "PLUS" .. area]
    local res_savestate = savestate_names[area_memory][room_memory]
    forms.setdropdownitems(INDIVIDUAL_STATE_MENU,res_savestate)
end

local function load_current_area()
    local area = forms.gettext(AREA_MENU)
    local area_memory = name_to_area[area]
    local res_rooms = {}
    for key,_ in pairs(savestate_names[area_memory]) do
        table.insert(res_rooms,RMNM.mem_to_rooms(key))
    end
    forms.setdropdownitems(ROOM_MENU,res_rooms)
end

-- window
FORM = forms.newform(300,200, "ROOM TRAINER")

-- drop down menus
AREA_MENU = forms.dropdown(FORM,areasnames,10,10,170,20) -- items to set
ROOM_MENU = forms.dropdown(FORM,{"blank room"},10,40,170,20)   -- items to set
INDIVIDUAL_STATE_MENU = forms.dropdown(FORM,{"blank state"},10,70,170,20)

-- buttons to update menus / load savestates
LOAD_AREA = forms.button(FORM,"Show Rooms",load_current_area,190,10,100,20)
LOAD_ROOM = forms.button(FORM,"Show States",load_current_room,190,40,100,20)
LOAD_BUTTON = forms.button(FORM,"Load",load_current_state,10,100,100,20)

-- checks to enable/disable functionalities
ROOM_PRACTICE_CHECK = forms.checkbox(FORM,"Room-Only Mode",10,130)
TIMER_CHECK = forms.checkbox(FORM,"Show Timer",10,160)
SHUFFLE_RNG = forms.checkbox(FORM,"Shuffle RNG",120,130)

local current_roomandarea = 0x0
local previous_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")
savestate.save(path .. temp_save)

while true do
    timer_frames = timer_frames + 1
    current_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

    if current_roomandarea ~= previous_roomandarea and forms.ischecked(ROOM_PRACTICE_CHECK) then
        savestate.load(path .. temp_save)
        timer_frames = 0
        if forms.ischecked(SHUFFLE_RNG) then
            -- thankfully, it just so happens that time is less than 2^32 so is a very good placeholder for a random rng value
            -- nevertheless, time may not be the best since counting rng up to the value obtained may take 2^31 tries on average, that is 2^31 evaluation of the rng function, which is very time consuming and will make bizhawk crash
            memory.write_u32_le(0x1150,os.time(),"IWRAM")
        end
    elseif current_roomandarea ~= previous_roomandarea then
        savestate.save(path .. temp_save)
        timer_frames = 0
        if forms.ischecked(SHUFFLE_RNG) then
            memory.write_u32_le(0x1150,os.time(),"IWRAM")

        end
    end

    if forms.ischecked(TIMER_CHECK) then
        gui.drawText(150,5,tostring(timer_frames) .. " f","cyan","black",12)
        gui.drawText(150,20,tostring((timer_frames//6)/10) .. " sec","pink","black",12)
    else
        gui.clearGraphics()
    end
    previous_roomandarea = current_roomandarea

    emu.frameadvance()
end