RMNM = require "roomnames"   -- Lua file containing tables that translate memory addresses to names
ORM = require "orderedrooms"    -- Lua file containing every room visited in any% in order
STT = require "savestates"
local path = '..\\GBA\\State\\'
local temp_save = 'temporary_savestate.State'

-- everything here is from the savestates module, replaces the need for savestates
local database = STT.get_database()
local iwram_database = STT.get_iwram_database()
local ewram_database = STT.get_ewram_database()
local goals = STT.get_goals()

local fmr = 59.7275 -- gba native framerate

local timer_frames = 0
local menu_time = 0
local wasloaded = false
local pb_cooldown = 0
local buffer = 0
local time_taken_display_counter = 0
local time_taken_display = ""

local pb_string = ""
local pb_inseconds = 0

local current_name = ""
local previous_name = current_name

local name_to_area = {}
local name_to_room = {}
local areasnames = {}

local savestate_names = {}
-- this for loop goes through every room and associate them with their respective memory values, initializes some variables, and such
for name,table_ in pairs(iwram_database) do  -- contains room&area corresponding to names
    local roomareavalue = string.format("%x",table_["2b"][0x10AC])
    while string.len(roomareavalue) < 4 do
        roomareavalue = '0' .. roomareavalue  -- room ids can be 00 and such, which is lost in translation to string.format method
    end
    local temp_area = string.upper(string.sub(roomareavalue,3,4))
    local temp_room = string.upper(string.sub(roomareavalue,1,4))
    if savestate_names[temp_area] == nil then   -- if a value is not assigned yet
        savestate_names[temp_area] = { [temp_room] = {name} }
        name_to_area[RMNM.mem_to_areas(temp_area)] = temp_area
        name_to_room[RMNM.mem_to_rooms(temp_room) .. "PLUS" .. RMNM.mem_to_areas(temp_area)] = temp_room
        table.insert(areasnames,RMNM.mem_to_areas(temp_area))
    else
        if savestate_names[temp_area][temp_room] == nil then
            savestate_names[temp_area][temp_room] = {name}
            name_to_room[RMNM.mem_to_rooms(temp_room) .. "PLUS" .. RMNM.mem_to_areas(temp_area)] = temp_room
        else
            table.insert(savestate_names[temp_area][temp_room],name)
        end
    end
end

local function key_is_in(element,tbl)
    local bool = false
    for key,_ in pairs(tbl) do
        if key == element then 
            bool = true 
            break
        end
    end
    return bool
end

local function value_is_in(element,tbl)
    local bool = false
    for _,val in pairs(tbl) do
        if val == element then 
            bool = true
            break
        end
    end
    return bool
end

local function warp(name)
    local wrb = memory.writebyte
    wrb(0x02032EC4, 0x00)  -- game state -> set to gameplay
    wrb(0x3F8D,0xFF,"IWRAM")   -- movement direction to neutral
    wrb(0x1002,0x02,"IWRAM")   -- game task -> set to in-game rather than file select or something else
    wrb(0x03000FD2, 0xF8) -- White Transition (looks kinda weird ? fix it idk) or is it 0FDC for black transition maybe ?
    wrb(0x030010A8, 0x01) -- Initializing Teleport
    for address,value in pairs(iwram_database[name]["1b"]) do
        wrb(address,value,"IWRAM")  -- sets every other characteristic data, like coordinates, layer, etc
    end
    for address,value in pairs(iwram_database[name]["2b"]) do
        memory.write_u16_le(address,value,"IWRAM")
    end
    for address,value in pairs(iwram_database[name]["4b"]) do
        memory.write_u32_le(address,value,"IWRAM")
    end
    for address,value in pairs(ewram_database[name]) do
        wrb(address,value,"EWRAM")
    end
end

local function writeflags(name)
    for address,value in pairs(database[name]) do
        memory.writebyte(address,value,"EWRAM")
    end
end

local function load_current_state()
    local name = forms.gettext(INDIVIDUAL_STATE_MENU)
    local roomareavalue = string.format("%x",iwram_database[name]["2b"][0x10AC])
    while string.len(roomareavalue) < 4 do
        roomareavalue = '0' .. roomareavalue  -- room ids can be 00 and such, which is lost in translation to string.format method
    end
    wasloaded = true
    timer_frames = 0
    current_name = name
    writeflags(name)
    warp(name)
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
    local name = forms.gettext(ROOMS_IN_ORDER)
    current_name = name
    writeflags(name)
    warp(name)
    wasloaded = true
    timer_frames = 0
end

local function find_room_index(rooms,name)
    -- finds the index of the room corresponding to name in rooms list
    local index = 1
    while rooms[index] ~= name do
        index = index + 1
    end
    return index
end

local function next_room()  -- travels the ROOMS_IN_ORDER table until it reaches the current name to get its index
    local name = forms.gettext(ROOMS_IN_ORDER)
    local rooms = ORM.get_rooms()
    name = rooms[find_room_index(rooms,name)+1]
    forms.settext(ROOMS_IN_ORDER,name)
    load_ordered()
end

local function prev_room()
    local name = forms.gettext(ROOMS_IN_ORDER)
    local rooms = ORM.get_rooms()
    name = rooms[find_room_index(rooms,name)-1]
    forms.settext(ROOMS_IN_ORDER,name)
    load_ordered()
end

local function reset_room()
    savestate.load(path .. temp_save)
    timer_frames = 0
    menu_time = 0
    wasloaded = true
    buffer = 2
end

-- window
FORM = forms.newform(320,280, "ROOM TRAINER")

-- drop down menus
AREA_MENU = forms.dropdown(FORM,areasnames,10,10,170,20) -- items to set
ROOM_MENU = forms.dropdown(FORM,{"click on show rooms"},10,40,170,20)   -- items to set
INDIVIDUAL_STATE_MENU = forms.dropdown(FORM,{"click on show states"},10,70,170,20)

-- buttons to update menus / load savestates
LOAD_AREA = forms.button(FORM,"Show Rooms",load_current_area,190,10,100,20)
LOAD_ROOM = forms.button(FORM,"Show States",load_current_room,190,40,100,20)
LOAD_BUTTON = forms.button(FORM,"Load",load_current_state,10,100,100,20)
RESET_BUTTON = forms.button(FORM,"Reset",reset_room,190,100,100,20)

-- checks to enable/disable functionalities
ROOM_PRACTICE_CHECK = forms.checkbox(FORM,"Reset Room",10,130)
TIMER_CHECK = forms.checkbox(FORM,"Show Timer",10,160)
SHUFFLE_RNG = forms.checkbox(FORM,"Shuffle RNG",120,130)
MENU_TIME = forms.checkbox(FORM,"Time in Menu",120,160)
PB_CHECK = forms.checkbox(FORM,"Show PB",230,130)

-- drop down menu of all the rooms in order in the route
forms.label(FORM,"Every Room in Order:",10,200,150,15)
ROOMS_IN_ORDER = forms.dropdown(FORM,{"placeholder"},10,220,300,20)
LOAD_ORDER = forms.button(FORM,"Load",load_ordered,10,250,100,20)
PREV_ROOM = forms.button(FORM,"< Previous",prev_room,120,250,80,20)
NEXT_ROOM = forms.button(FORM,"Next >",next_room,210,250,80,20)

forms.setdropdownitems(ROOMS_IN_ORDER,ORM.get_rooms(),false)    -- this keeps the saves in order, this is also the key to identifying rooms

local function is_pb(t) -- compares time t to pb time, and if lower, updates the file
    -- /!\ you need to create an empty text file named room_pb.txt beforehand /!\
    local file = io.open("room_pb.txt", "r")
    local fileContent, name, time = {}, "", ""
    while true do
        local line = file:read("*l")
        if line ~= nil then
            local start,_ = string.find(line,"%s%S*.$",1,false) -- matches the number at the end of the name and the number of frames of the pb
            name = string.sub(line,1,start-1)
            time = string.sub(line,start+1,-1)
            fileContent[name] = time
        else
            break
        end
    end
    file:close()

    if fileContent[current_name] == nil or tonumber(fileContent[current_name]) > t then
        fileContent[current_name] = t
    end

    local newfile = io.open("room_pb.txt", "w")
    for key,value in pairs(fileContent) do
        newfile:write(key .. " " .. value .. "\n")
    end
    newfile:close()
end

local function check_goals()
    local succeeded = true
    for goal,value in pairs(goals[current_name]) do
        if memory.read_u8(goal,"EWRAM") ~= value then
            succeeded = false
            break
        end
    end
    return succeeded
end

local function display_pb()
    -- finds the corresponding room name in the text file
    local file = io.open("room_pb.txt", "r")
    local file_string = file:read("*a")
    file_string = string.gsub(file_string,"[%(%)%.%%%+%-%*%?%[%^%$]","")    -- eliminates special characters (from regex) bc they mess up with the find method
    local name_replacement = string.gsub(current_name,"[%(%)%.%%%+%-%*%?%[%^%$]","%1")
    local line_index = string.find(file_string,name_replacement)
    if line_index then
        -- make this code look nicer maybe ??
        local next_line_index,_ = line_index - 1 + string.find(string.sub(file_string,line_index,-1),"\n")
        local start,_ = line_index - 1 + string.find(string.sub(file_string,line_index,next_line_index),"%s%S*.$",1,false)
        pb_string = string.sub(file_string,start+1,next_line_index-1)
        pb_inseconds = math.floor(100*tonumber(pb_string)/fmr)/100  -- converts the frame count to seconds with a precision to the 100th
    else
        pb_string = "?"
    end
    file:close()
end

local current_roomandarea = 0x0
local previous_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")
savestate.save(path .. temp_save)

while true do
    timer_frames = timer_frames + 1
    current_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

    if current_roomandarea ~= previous_roomandarea then
        local name = ORM.get_rooms()[find_room_index(ORM.get_rooms(),current_name)+1] -- next room name
        if not wasloaded and pb_cooldown == 0 and check_goals() and iwram_database[name]["2b"][0x10AC] == current_roomandarea then
            is_pb(timer_frames)
            pb_cooldown = 2
        end

        if buffer == 0 then
            time_taken_display_counter = 90
            time_taken_display = tostring(math.floor(100*(timer_frames)/fmr)/100)
        end
        timer_frames = 0
        menu_time = 0

        -- this is supposed to distinguish between having to load the room again vs having to remember the current room as a savestate
        if forms.ischecked(ROOM_PRACTICE_CHECK) then
            savestate.load(path .. temp_save)
            wasloaded = true
            buffer = 2
        else
            savestate.save(path .. temp_save)
            if not wasloaded then
                if iwram_database[name]["2b"][0x10AC] == current_roomandarea then -- if next room (in order) and current room memory match then
                    current_name = name
                end
            end
        end

        if forms.ischecked(SHUFFLE_RNG) then
            -- thankfully, it just so happens that time is less than 2^32 so is a very good placeholder for a random rng value
            -- nevertheless, time may not be the best since counting rng up to the value obtained may take 2^31 tries on average, that is 2^31 evaluation of the rng function, which is very time consuming and will make bizhawk crash
            memory.write_u32_le(0x1150,os.time(),"IWRAM")
        end

        display_pb()
    end

    if forms.ischecked(TIMER_CHECK) then
        gui.drawText(175,30,tostring(timer_frames) .. " f","cyan","black",12)
        gui.drawText(175,45,tostring((timer_frames//6)/10) .. " sec","pink","black",12) -- needs normalization of fps
    else
        gui.clearGraphics()
    end

    if forms.ischecked(MENU_TIME) then
        if memory.read_u16_le(0x10CF,"IWRAM") == 0x0100 then    -- time spent in menu
            menu_time = menu_time + 1  
        end
        gui.drawText(160,137,tostring(menu_time) .. " f : menu","lime","black",10)
    end

    if forms.ischecked(PB_CHECK) then
        if pb_string ~= "?" then
            gui.drawText(10,20,"PB : " .. tostring(pb_inseconds) .. " sec","white","black",12)
        else
            gui.drawText(10,20,"PB : ?","white","black",12)
        end
    end

    if pb_cooldown > 0 then pb_cooldown = pb_cooldown - 1 end
    if buffer > 0 then buffer = buffer - 1 end

    if time_taken_display_counter > 0 and forms.ischecked(TIMER_CHECK) then
        time_taken_display_counter = time_taken_display_counter - 1
        gui.drawText(80,50,time_taken_display .. " sec","red","black",15)
    end

    previous_roomandarea = current_roomandarea
    previous_name = current_name
    wasloaded = false

    emu.frameadvance()
end
