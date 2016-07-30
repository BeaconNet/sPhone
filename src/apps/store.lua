local host = "https://raw.github.com/Sertex-Team/sPhone-Store/master/"
local index = host.."index.lua"
local apps = host.."apps/"
local save = "/.sPhone/apps/storeApps/"
local db = "/.sPhone/apps/storeData/database"
local appsL = {}
local w, h = term.getSize()
local function redrawM()
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.black)
	term.clear()
	term.setCursorPos(1,1)
	term.setTextColor(colors.white)
	paintutils.drawLine(1,1,w,1,colors.orange)
	visum.align("right","X",false,1)
	visum.align("center","  Store",false,1)
	term.setTextColor(colors.black)
	term.setBackgroundColor(colors.white)
	term.setCursorPos(1,3)
end

redrawM()

term.setCursorPos(1,2)
visum.align("center","  Loading",false,2)
term.setCursorPos(1,3)

local c = http.get(index).readAll()

local appsIndex = textutils.unserialize(c)

for k, v in pairs(appsIndex) do
	local aa = http.get(apps..v.."/sPhone-Main.lua").readAll()
	local a = textutils.unserialize(aa)
	table.insert(appsL,a)
end
function redrawA()
	for i = 1, #appsL do
		print(appsL[i].name)
	end
end

local function redraw()
	redrawM()
	redrawA()
end
redrawA()
local mx,my = term.getCursorPos()
term.setCursorPos(1,2)
term.clearLine()
term.setCursorPos(mx,my)


while true do
	redraw()
	local _, _, x, y = os.pullEvent("mouse_click")
	if x == w and y == 1 then
		break
	end
	
	if appsL[y-2] then
		local data = http.get("https://raw.github.com/Sertex-Team/sPhone-Store/master/apps/"..appsL[y-2].storePath.."/"..appsL[y-2].main).readAll()
		local f = fs.open("/.sPhone/apps/storeApps/"..appsL[y-2].name.."/"..appsL[y-2].main,"w")
		f.write(data)
		f.close()
		local f = fs.open("/.sPhone/apps/storeApps/"..appsL[y-2].name.."/sPhone-Main.lua","w")
		f.write(textutils.serialize(appsL[y-2]))
		f.close()
		sPhone.winOk("Installed")
	end
end
