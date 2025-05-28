RMNM = require "roomnames"   -- Lua file containing tables that translate memory addresses to names
ORM = require "orderedrooms"    -- Lua file containing every room visited in any% in order
local statepath = '..\\GBA\\State\\ROOMTRAINERFOLDER\\'    -- append the name of a savestate file to the path for it to load properly with savestate.load()
local path = '..\\GBA\\State\\'    -- path to State folder in which we save the temporary save for the room-only mode
local temp_save = 'temporary_savestate.State'

local timer_frames = 0
local menu_time = 0
local time_taken_display_counter = 0
local time_taken_display = ""
local buffer = 0

local name_to_area = {}
local name_to_room = {}
local areasnames = {}

-- reads through the ROOMTRAINERFOLDER directory to get each savestate name in a table
local savestate_names = {}  -- [1 hex byte] (area memory value) = { [2 hex bytes] (room memory value) = rooms }
for dir in io.popen([[dir "..\GBA\State\ROOMTRAINERFOLDER\" /b]]):lines() do   -- lists every savestate name into the savestate_names table, associating a room + area to one or more savestates
    local temp_area = string.upper(string.sub(dir,3,4))    -- making the hex values uppercase so that it corresponds to the format used in the excel file
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
    local area_memory = name_to_area[area]
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

local function load_ordered()
    local splitted = string.gmatch(forms.gettext(ROOMS_IN_ORDER),"([^#]+)")
    local area = string.sub(splitted(1),1,-2)
    local room = string.sub(splitted(2),2,-2)
    local multiple = string.sub(splitted(3),2)
    local area_memory = name_to_area[area]
    local room_memory = name_to_room[room .. "PLUS" .. area]
    local res_savestate = savestate_names[area_memory][room_memory][tonumber(multiple)+1]
    savestate.load(statepath .. res_savestate)
    savestate.save(path .. temp_save)
    timer_frames = 0
end

local function next_room()
    local name = forms.gettext(ROOMS_IN_ORDER)
    local index = 1
    local rooms = ORM.get_rooms()
    while rooms[index] ~= name do
        index = index + 1
    end
    name = rooms[index+1]
    forms.settext(ROOMS_IN_ORDER,name)
    load_ordered()
end

local function prev_room()
    local name = forms.gettext(ROOMS_IN_ORDER)
    local index = 1
    local rooms = ORM.get_rooms()
    while rooms[index] ~= name do
        index = index + 1
    end
    name = rooms[index-1]
    forms.settext(ROOMS_IN_ORDER,name)
    load_ordered()
end

-- window
FORM = forms.newform(320,280, "ROOM TRAINER")

-- drop down menus
AREA_MENU = forms.dropdown(FORM,areasnames,10,10,170,20)
ROOM_MENU = forms.dropdown(FORM,{"blank room"},10,40,170,20)
INDIVIDUAL_STATE_MENU = forms.dropdown(FORM,{"blank state"},10,70,170,20)

-- buttons to update menus / load savestates
LOAD_AREA = forms.button(FORM,"Show Rooms",load_current_area,190,10,100,20)
LOAD_ROOM = forms.button(FORM,"Show States",load_current_room,190,40,100,20)
LOAD_BUTTON = forms.button(FORM,"Load",load_current_state,10,100,100,20)

-- checks to enable/disable functionalities
ROOM_PRACTICE_CHECK = forms.checkbox(FORM,"Room-Only Mode",10,130)
TIMER_CHECK = forms.checkbox(FORM,"Show Timer",10,160)
SHUFFLE_RNG = forms.checkbox(FORM,"Shuffle RNG",120,130)
MENU_TIME = forms.checkbox(FORM,"Time in Menu",120,160)

-- drop down menu of all the rooms in order in the route
forms.label(FORM,"Every Room in Order:",10,200,150,15)
ROOMS_IN_ORDER = forms.dropdown(FORM,{"placeholder"},10,220,300,20)
LOAD_ORDER = forms.button(FORM,"Load",load_ordered,10,250,100,20)
PREV_ROOM = forms.button(FORM,"< Previous",prev_room,120,250,80,20)
NEXT_ROOM = forms.button(FORM,"Next >",next_room,210,250,80,20)

forms.setdropdownitems(ROOMS_IN_ORDER,ORM.get_rooms(),false)    -- this keeps the saves in order

local current_roomandarea = 0x0
local previous_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")
savestate.save(path .. temp_save)

while true do
    timer_frames = timer_frames + 1
    current_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

    if current_roomandarea ~= previous_roomandarea and forms.ischecked(ROOM_PRACTICE_CHECK) then
        savestate.load(path .. temp_save)
        if buffer == 0 then
            time_taken_display_counter = 90
            time_taken_display = tostring(timer_frames)
            buffer = 2
        end
        timer_frames = 0
        menu_time = 0
        if forms.ischecked(SHUFFLE_RNG) then
            -- thankfully, it just so happens that time is less than 2^32 so is a very good placeholder for a random rng value
            -- nevertheless, time may not be the best since counting rng up to the value obtained may take 2^31 tries on average, that is 2^31 evaluation of the rng function, which is very time consuming and will make bizhawk crash
            -- you could instead use the math.random(2**32) native Lua function to generate a random number between 1 and and 2^32 and then assign in to address 0x1150, not sure if it costs more ressources or not
            memory.write_u32_le(0x1150,os.time(),"IWRAM")
        end
    elseif current_roomandarea ~= previous_roomandarea then
        savestate.save(path .. temp_save)
        time_taken_display_counter = 90
        time_taken_display = tostring(timer_frames)
        timer_frames = 0
        menu_time = 0
        if forms.ischecked(SHUFFLE_RNG) then
            memory.write_u32_le(0x1150,os.time(),"IWRAM")

        end
    end

    if forms.ischecked(TIMER_CHECK) then
        gui.drawText(175,30,tostring(timer_frames) .. " f","cyan","black",12)
        gui.drawText(175,45,tostring((timer_frames//6)/10) .. " sec","pink","black",12)
    else
        gui.clearGraphics()
    end

    if forms.ischecked(MENU_TIME) then    -- displays the timer for a specific room since you entered it in frames and seconds
        if memory.read_u16_le(0x10CF,"IWRAM") == 0x0100 then
            menu_time = menu_time + 1  
        end
        gui.drawText(160,137,tostring(menu_time) .. " f : menu","lime","black",10)
    end

    if time_taken_display_counter > 0 and forms.ischecked(TIMER_CHECK) then    -- displays the time taken at the end of each room
        time_taken_display_counter = time_taken_display_counter - 1
        gui.drawText(95,50,time_taken_display .. " f","red","black",15)
    end

    if buffer > 0 then buffer = buffer - 1 end

    previous_roomandarea = current_roomandarea

    emu.frameadvance()
end
