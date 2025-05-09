local savestatepath = '..\\GBA\\State\\TESTFOLDER\\'
local states_table = {}

local current_roomandarea = 0x0
local previous_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")


while memory.read_u8(0x1744,"IWRAM") ~= 0x0D do -- vaati 3 is dead memory value

    current_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

    if current_roomandarea ~= previous_roomandarea then -- if room or area changes, save a new savestate with an original name corresponding to room, area and multiples
        local temp_key = string.format("%x",current_roomandarea)
        while string.len(temp_key) < 4 do
            temp_key = '0' .. temp_key  -- room ids can be 00 and such, which is lost in translation to string.format method
        end
        local count = 0
        if states_table[temp_key] == nil then
            states_table[temp_key] = {'state0'}
        else
            for _,_ in ipairs(states_table[temp_key]) do
                count = count + 1
            end
            states_table[temp_key][count+1] = 'state' .. string.format(count)
        end
        savestate.save(savestatepath .. temp_key .. 'state' .. string.format(count) .. '.State')    -- saving the savestate with the appropriate name
    end

    previous_roomandarea = current_roomandarea

    emu.frameadvance()
end

-- ran once