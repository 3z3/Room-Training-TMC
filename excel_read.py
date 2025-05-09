import openpyxl

wb = openpyxl.load_workbook('..\\TMCroomlist.xlsx')

ws = wb.active

memory_to_rooms = {}
memory_to_areas = {}

#example
#ws['B3'].value is None
#ws.cell(row=1,column=i).value iterates through columns using index i
#ws.max_column designates the highest column number

for i in range(2,ws.max_row+1):
    area_cell = ws.cell(row = i, column = 2)
    if area_cell.value is None or area_cell.fill.bgColor.rgb != 'FFFFFFFF':
        pass
    else:
        if area_cell.value not in memory_to_rooms:
            memory_to_areas[ws.cell(row = i, column = 1).value] = area_cell.value
            
        room_cell = ws.cell(row = i, column = 4)
        if room_cell.value is None or room_cell.fill.bgColor.rgb != 'FFFFFFFF':
            pass
        else:
            memory_to_rooms[ws.cell(row = i, column = 3).value + ws.cell(row = i, column = 1).value] = room_cell.value

mtrstring = 'memory_to_rooms = {'
mtastring = 'memory_to_areas = {'

for key,value in memory_to_rooms.items():
    mtrstring += ' ["' + key + '"] = "' + value + '",'
mtrstring[:-1] += ' }\n'    #getting rid of the last comma at the end

for key,value in memory_to_areas.items():
    mtastring += ' ["' + key + '"] = "' + value + '",'
mtastring[:-1] += ' }'

with open("roomnames.Lua", "w") as f:
  f.writelines([mtrstring,mtastring])