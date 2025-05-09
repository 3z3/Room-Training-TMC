local savestatepath = '..\\GBA\\State\\ROOMTRAINERFOLDER\\'    -- create a folder named ROOMTRAINERFOLDER in the State folder of Bizhawk beforehand
local states_table = {}

-- /!\ this script is designed to run while a movie of a TMC category full run plays back

local current_roomandarea = 0x0
local previous_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

-- uncomment this line if you want to replay your movie at 500% speed so that it does not take as long
-- client.speedmode(500)

while memory.read_u8(0x1744,"IWRAM") ~= 0x0D do -- vaati 3 is dead memory value

    current_roomandarea = memory.read_u16_le(0x10AC,"IWRAM")

    if current_roomandarea ~= previous_roomandarea then -- if room or area changes, save a new savestate with an original name corresponding to room, area and multiples
        local temp_key = string.format("%x",current_roomandarea)
        while string.len(temp_key) < 4 do
            temp_key = '0' .. temp_key  -- room ids can be 00 and such, which is lost in translation to string.format method
        end
        local count = 0
        if states_table[temp_key] == nil then
            states_table[temp_key] = {'state0'}    -- states are going to be saved according to the following syntax : 0188state0.State for example is the first savestate of the Top Left Corner Key Chest room of Dark Hyrule Castle
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
