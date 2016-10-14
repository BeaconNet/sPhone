local function kernel()
	_G.sPhone = {
		version = "Alpha 4",
		user = "Guest",
		devMode = false,
		mainTerm = term.current(),
		safeMode = false,
	}
	
	if safemode then
		sPhone.safeMode = true
		_G.safemode = nil
	end
	
	sPhone.defaultApps = {
		["home"] = "/.sPhone/apps/home",
	}
	
	sPhone.theme = { --Default colors
		["header"] = colors.blue,
		["headerText"] = colors.white,
		["text"] = colors.black,
		["background"] = "",
		["backgroundColor"] = colors.white,
		["window.background"] = colors.lightBlue,
		["window.side"] = colors.blue,
		["window.button"] = colors.lightBlue,
		["window.text"] = colors.white,
	}
	
	sPhone.defaultTheme = sPhone.theme
	
	if not fs.exists("/.sPhone/apis") then
		fs.makeDir("/.sPhone/apis")
	end
	
	for k, v in pairs(fs.list("/.sPhone/apis")) do
		if not fs.isDir("/.sPhone/apis/"..v) then
			os.loadAPI("/.sPhone/apis/"..v)
		end
	end

	local sPath = shell.path()
	sPath = sPath..":/bin"
	shell.setPath(sPath)
	
	if not fs.exists("/.sPhone/autorun") then
		fs.makeDir("/.sPhone/autorun")
	end
	
	term.setBackgroundColor(colors.white)
	term.clear()
	term.setCursorPos(1,1)
	for k, v in pairs(fs.list("/.sPhone/autorun")) do
		term.setTextColor(colors.black)
		if not fs.isDir("/.sPhone/autorun/"..v) then
			if not sPhone.safemode then
				local f = fs.open("/.sPhone/autorun/"..v,"r")
				local script = f.readAll()
				f.close()
				print("Loading script "..v)
				sleep(0)
				local ok, err = pcall(function() setfenv(loadstring(script),getfenv())() end)
				if not ok then
					term.setTextColor(colors.red)
					print("Script error: "..v..": "..err)
					fs.move("/.sPhone/autorun/"..v, "/.sPhone/autorun/disabled/"..v)
					term.setTextColor(colors.blue)
					print(v.." disabled to prevent errors")
					sleep(0.5)
				end
			else
				print("Script "..v.." not loaded because Safe Mode")
				sleep(0)
			end
		end
	end
	
	if runningOnStartup then
		fs.open("/startup","r")
	end
	
	if fs.exists("/.sPhone/config/username") then
		local u = fs.open("/.sPhone/config/username","r")
		sPhone.user = u.readLine()
		u.close()
	end
	
	if not fs.exists("/.sPhone/config/sPhone") then
		config.write("/.sPhone/config/sPhone","devMode",false)
	end
	
	sPhone.devMode = config.read("/.sPhone/config/sPhone","devMode")
	
	if sPhone.devMode then
		sPhone.crash = crash
	end
	
	_G.crash = nil
	
	function os.version()
		return "sPhone "..sPhone.version
	end
	
	function sPhone.getSize()
		return term.getSize()
	end
	
	local fileTheme = "/.sPhone/config/theme"
	if fs.exists(fileTheme) then
		sPhone.theme["header"] = config.read(fileTheme, "header")
		sPhone.theme["headerText"] = config.read(fileTheme, "headerText")
		sPhone.theme["text"] = config.read(fileTheme, "text")
		sPhone.theme["background"] = config.read(fileTheme, "background")
		sPhone.theme["backgroundColor"] = config.read(fileTheme, "backgroundColor")
		sPhone.theme["window.background"] = config.read(fileTheme, "window.background")
		sPhone.theme["window.side"] = config.read(fileTheme, "window.side")
		sPhone.theme["window.button"] = config.read(fileTheme, "window.button")
		sPhone.theme["window.text"] = config.read(fileTheme, "window.text")
	else
		for k, v in pairs(sPhone.theme) do
			config.write(fileTheme, k, v)
		end
	end
	
	function sPhone.applyTheme(id, value)
		if not value or not id then
			error("bad arguement: double expected, got nil",2)
		end
		sPhone.theme[id] = value
		config.write(fileTheme, id, value)
	end
	
	function sPhone.getTheme(id)
		if not id then
			error("bad arguement: double expected, got nil",2)
		end
		local n = config.read(fileTheme, id)
		return n
	end
	
	function sPhone.setDefaultApp(app, path)
		if not path then
			error("got nil",2)
		end
		
		sPhone.defaultApps[app] = path
		config.write("/.sPhone/config/defaultApps",app,path)
	end
	
	function sPhone.getDefaultApp(app)
		if not app then
			error("got nil",2)
		end
		
		local n = config.read("/.sPhone/config/defaultApps",app)
		return n
	end
	
	if not fs.exists("/.sPhone/config/defaultApps") then
		sPhone.setDefaultApp("home","/.sPhone/apps/home")
	end
	
	local function clear()
		term.setBackgroundColor(sPhone.theme["backgroundColor"])
		term.clear()
		term.setCursorPos(1,1)
		term.setTextColor(sPhone.theme["text"])
	end
	
	sPhone.forceShutdown = os.shutdown
	sPhone.forceReboot = os.reboot
	
	function os.shutdown()
		sPhone.inHome = false
		os.pullEvent = os.pullEventRaw
		while true do
			if sPhone.doneShutdown then
				clear()
				w, h = term.getSize()
				term.setCursorPos( (w/2)- 7, h/2)
				write("Shutdown Aborted.")
				sPhone.winOk("Error","Can not shutdown",colors.lightBlue,colors.red, colors.white, colors.lightBlue)
				return
			end
			sPhone.doneShutdown = true
			clear()
			w, h = term.getSize()
			term.setCursorPos( (w / 2) - 1, h / 2)
			for i = 1,3 do
				sleep(0.3)
				write(".")
			end
			sleep(0.2)
			sPhone.forceShutdown()
		end
	end
	
	function os.reboot()
		sPhone.inHome = false
		os.pullEvent = os.pullEventRaw
		while true do
			if sPhone.doneShutdown then
				clear()
				w, h = term.getSize()
				term.setCursorPos( (w/2)- 7, h/2)
				write("Reboot Aborted.")
				sPhone.winOk("Error","Can not reboot",colors.lightBlue,colors.red, colors.white, colors.lightBlue)
				return
			end
			sPhone.doneShutdown = true
			clear()
			w, h = term.getSize()
			term.setCursorPos( (w / 2) - 1, h / 2)
			for i = 1,3 do
				sleep(0.3)
				write(".")
			end
			sleep(0.2)
			sPhone.forceReboot()
		end
	end
  
  function sPhone.header(title, butt)
		
		if not title then
			title = "sPhone"
		end

		local w, h = term.getSize()
		paintutils.drawLine(1,1,w,1, sPhone.theme["header"])
		term.setTextColor(sPhone.theme["headerText"])
		term.setCursorPos(1,1)
		write(" "..title)
		term.setCursorPos(w,1)
		if butt then
			write(butt)
		end
		term.setBackgroundColor(sPhone.theme["backgroundColor"])
		term.setTextColor(sPhone.theme["text"])
		term.setCursorPos(1,3)
  end
  
  function sPhone.menu(items, title, closeButton)
    local function cprint(text)
      if type(text) ~= 'table' then
        text = {text}
      end
	
      local w, h = term.getSize()
	
      for i=1,#text do
        local x, y = term.getCursorPos()
        term.setCursorPos(math.floor(w/2)-math.floor(text[i]:len()/2), y)
        print(text[i])
      end
    end
    local function clear()
      term.clear()
      term.setCursorPos(1, 1)
    end
	
    local termWidth, termHeight = term.getSize()
    local drawSize = termHeight - 6
	
    local function maxPages()
    local itemCount = #items
    local pageCount = 0
		while itemCount > 0 do
			itemCount = itemCount - drawSize
			pageCount = pageCount + 1
		end
		return pageCount
	end
	
	local function iif(cond, trueval, falseval)
		if cond then
			return trueval
		else
			return falseval
		end
	end
	
	local function pagedItems()
		local ret = {}
		for i = 1, maxPages() do
			local tmp = {}
			local nElements = 0
			for j = drawSize*(i-1)+1, iif(drawSize*(i+1) > #items, #items, drawSize*(i+1)) do
				if nElements < drawSize then
					table.insert(tmp, items[j])
					nElements = nElements + 1
				end
			end
			table.insert(ret, tmp)
		end
		return ret
	end
	
	local selected = 1
	if start then
		selected = start
	end
	local page = 1
	
	local function redraw()
		term.setBackgroundColor(sPhone.theme["backgroundColor"])
		term.setTextColor(sPhone.theme["text"])
		term.clear()
    term.setCursorPos(1,1)
		sPhone.header("",closeButton)
		term.setCursorPos(1,3)
		if not title then
			title = "  sPhone"
		end
		cprint("  "..title)
		if moreTitle then
			head = moreTitle
		else
			head = {"\n",}
			if not allowNil or allowNil == true then
				--head[3] = 'Terminate to cancel.'
			end
		end
		for i=1,#head do
			print(head[i])
		end
		if maxPages() > 1 then
			pages = "<- (page "..page.." of "..maxPages()..") ->"
			print(pages)
		end
		for i = 1, #pagedItems()[page] do
			if selected == drawSize*(page-1)+i then
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				term.setTextColor(sPhone.theme["text"])
			else
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				term.setTextColor(sPhone.theme["text"])
			end
			term.clearLine()
			cprint(iif(selected == drawSize*(page-1)+i,"","").." "..pagedItems()[page][i])
			term.setBackgroundColor(sPhone.theme["backgroundColor"])
			term.setTextColor(sPhone.theme["text"])
		end
	end

	local function changePage(pW)
		if pW == 1 and page < maxPages() then
			page = page + 1
			if selected + drawSize > #items then
				selected = #items
			else
				selected = selected + drawSize
			end
		elseif pW == -1 and page > 1 then
			page = page - 1
			if selected - drawSize < 1 then
				selected = 1
			else
				selected = selected - drawSize
			end
		end
	end
	
	while true do
		redraw()
		local eventData = {os.pullEventRaw()}
		if eventData[1] == 'mouse_click' then
			if eventData[4] == 1 and eventData[3] == termWidth then
				return false, 0
			elseif eventData[4] > 3 then
				clear()
				selected = (eventData[4]-6+((page-1)*drawSize))+1
				if selected then
					return items[selected], selected
				end
			end
		end
	end
end
	
	function sPhone.yesNo(title, desc, hideUser)
		term.setCursorBlink(false)
		term.setBackgroundColor(sPhone.theme["backgroundColor"])
		term.clear()
		term.setCursorPos(1,1)
		term.setTextColor(sPhone.theme["text"])
		local w, h = term.getSize()
		paintutils.drawLine(1,1,w,1, sPhone.theme["header"])
		term.setTextColor(sPhone.theme["headerText"])
		term.setCursorPos(1,1)
		if not hideUser then
			if not sPhone.user then
				write(" sPhone")
			else
				write(" "..sPhone.user)
			end
		end
		term.setCursorPos(1,3)
		term.setBackgroundColor(sPhone.theme["backgroundColor"])
		term.setTextColor(sPhone.theme["text"])
		visum.align("center", "  "..title, false, 3)
		if desc then
			visum.align("center", "  "..desc,false,6)
		end
		paintutils.drawFilledBox(3, 16, 9, 18, colors.green)
		paintutils.drawFilledBox(18, 16, 24, 18, colors.red)
		term.setTextColor(colors.white)
		term.setCursorPos(5,17)
		term.setBackgroundColor(colors.green)
		write("Yes")
		term.setCursorPos(20,17)
		term.setBackgroundColor(colors.red)
		write("No")
		while true do
			local _,_,x,y = os.pullEvent("mouse_click")
			if (x > 2 and y > 15) and (x < 10 and y < 19) then
				return true
			elseif (x > 17 and y > 15) and (x < 25 and y < 19) then
				return false
			end
		end
	end
	
	function sPhone.winOk(fmessage, smessage, bg, side, text, button)
		if not fmessage then
			fmessage = ""
		end
		if not smessage then
			smessage = ""
		end
		if not bg then
			bg = sPhone.theme["window.background"]
		end
		if not text then
			text = sPhone.theme["window.text"]
		end
		if not button then
			button = sPhone.theme["window.button"]
		end
		if not side then
			side = sPhone.theme["window.side"]
		end
		term.setCursorBlink(false)
		if #fmessage >= #smessage then
			local w, h = term.getSize
			term.setBackgroundColor(side)
			paintutils.drawBox(12 - math.ceil(#fmessage / 2), 5, 15 + math.ceil(#fmessage / 2), 10, side)
			term.setBackgroundColor(bg)
			paintutils.drawFilledBox(13 - math.ceil(#fmessage / 2), 6, 14 + math.ceil(#fmessage / 2), 9, bg)
			term.setCursorPos(14 - math.ceil(#fmessage / 2), 7)
			term.setTextColor(text)
			write(fmessage)
			term.setCursorPos(14 - math.ceil(#smessage / 2), 8)
			write(smessage)
		else
			local w, h = term.getSize
			term.setBackgroundColor(side)
			paintutils.drawBox(12 - math.ceil(#smessage / 2), 5, 15 + math.ceil(#smessage / 2), 10, side)
			term.setBackgroundColor(bg)
			paintutils.drawFilledBox(13 - math.ceil(#smessage / 2), 6, 14 + math.ceil(#smessage / 2), 9, bg)
			term.setCursorPos(14 - math.ceil(#fmessage / 2), 7)
			term.setTextColor(text)
			write(fmessage)
			term.setCursorPos(14 - math.ceil(#smessage / 2), 8)
			write(smessage)
		end
		term.setCursorPos(13,10)
		term.setBackgroundColor(button)
		write("Ok")
		while true do
			local e, k, x,y = os.pullEvent()
			if e == "mouse_click" then
				if y == 10 then
					if x == 13 or x == 14 then
						return
					end
				end
			elseif e == "key" then
				if k == 28 then
					return
				end
			end
		end
	end
	
	function sPhone.colorPicker(message, old) -- From Impulse
		local current = math.log(old) / math.log(2)
		-- first line is already code wizardry
		local function redraw()
			term.setBackgroundColour(sPhone.theme["backgroundColor"])
			term.clear()
			sPhone.header(message)
			term.setCursorPos(2,5)
			term.setTextColor(colors.white)
			term.setBackgroundColor(colors.lime)
			write(" Ok ")
			term.setCursorPos(7,5)
			term.setTextColor(colors.white)
			term.setBackgroundColor(colors.red)
			write(" Cancel ")
			term.setTextColor(colors.black)
			term.setCursorPos(2, 3)
			for i = 0, 15 do
				term.setBackgroundColour(2^i)
				term.write(i == current and "#" or ":")
			end
		end
		while true do
			redraw()
			local ev = {os.pullEvent()}
			if ev[1] == "key" and ev[2] == keys.enter then
				return 2^current
			elseif ev[1] == "mouse_click" then
				if ev[4] == 3 and ev[3] >= 2 and ev[3] <= 17 then
					current = ev[3] - 2 % 16
				elseif ev[4] == 5 and ev[3] >= 2 and ev[3] <= 6 then
					return 2^current
				elseif ev[4] == 5 and ev[3] >= 7 and ev[3] <= 14 then
					return old
				end
			end
		end
	end
	
	sPhone.colourPicker = sPhone.colorPicker -- For UK
	
	function sPhone.run(rApp, ...)
		if not fs.exists(rApp) or fs.isDir(rApp) then
			sPhone.winOk("App not found")
			return false
		end
		if sPhone.inHome then
			local sPhoneWasInHome = true
			sPhone.inHome = false
		end
		os.pullEvent = os.oldPullEvent
		local ok, err = pcall(function(...) setfenv(loadfile(rApp),getfenv())(...) end, ...)
		if not ok then
			os.pullEvent = os.pullEventRaw
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.black)
			term.clear()
			term.setCursorPos(1,2)
			visum.align("center","  "..fs.getName(rApp).." crashed",false,2)
			term.setCursorPos(1,4)
			print(err)
			print("")
			visum.align("center","  Press Any Key")
			os.pullEvent("key")
		end
		os.pullEvent = os.pullEventRaw
		if sPhoneWasInHome then
			sPhone.inHome = true
		end
	end
	
	local function home()
		sPhone.inHome = true
		while true do
			os.pullEvent = os.oldPullEvent
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.white)
			term.clear()
			term.setCursorPos(1,1)
			
			if not sPhone.safeMode then
				if fs.exists(sPhone.getDefaultApp("home")) then
					shell.run(sPhone.getDefaultApp("home"))
				else
					shell.run("/.sPhone/apps/home")
				end
			else
				shell.run("/.sPhone/apps/home")
			end
		end
		sPhone.inHome = false
	end
	
	function login()
		sPhone.locked = true
		if fs.exists("/.sPhone/config/.password") then
			while true do
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				term.clear()
				term.setCursorPos(1,1)
				sPhone.header(sPhone.user)
				paintutils.drawBox(7,9,20,11,sPhone.theme["window.background"])
				if sPhone.wrongPassword then
					term.setTextColor(colors.red)
					term.setBackgroundColor(sPhone.theme["backgroundColor"])
					visum.align("center","  Wrong Password",false,13)
				end
				term.setTextColor(sPhone.theme["text"])
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				visum.align("center","  Insert Password",false,7)
        local loginTerm = window.create(term.native(), 8,10,12,1, true)
        term.redirect(loginTerm)
        term.setBackgroundColor(sPhone.theme["backgroundColor"])
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(sPhone.theme["text"])
				local passwordLogin = read("*")
        term.redirect(sPhone.mainTerm)
				local fpw = fs.open("/.sPhone/config/.password","r")
				if sha256.sha256(passwordLogin) == fpw.readLine() then
					sPhone.wrongPassword = false
					return
				else
					sPhone.wrongPassword = true
				end
			end
		else
			local name
			local pw
			local pwr
			local rServer
			sPhone.firstBoot = true
			while true do
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				term.clear()
				term.setCursorPos(1,1)
				sPhone.header("Setup")
				paintutils.drawBox(7,9,20,11,sPhone.theme["window.background"])
				if sPhone.wrongPassword then
					term.setTextColor(colors.red)
					visum.align("center","  Wrong Password",false,13)
				end
				term.setTextColor(sPhone.theme["text"])
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				visum.align("center","  Insert Password",false,7)
        local loginTerm = window.create(term.native(), 8,10,12,1, true)
        term.redirect(loginTerm)
        term.setBackgroundColor(sPhone.theme["backgroundColor"])
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(sPhone.theme["text"])
				local password1 = read("*")
				term.redirect(sPhone.mainTerm)
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				term.clear()
				term.setCursorPos(1,1)
				sPhone.header("Setup")
				paintutils.drawBox(7,9,20,11,sPhone.theme["window.background"])
				term.setTextColor(sPhone.theme["text"])
				term.setBackgroundColor(sPhone.theme["backgroundColor"])
				visum.align("center","  Repeat",false,7)
        local loginTerm = window.create(term.native(), 8,10,12,1, true)
        term.redirect(loginTerm)
        term.setBackgroundColor(sPhone.theme["backgroundColor"])
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(sPhone.theme["text"])
				local password2 = read("*")
				term.redirect(sPhone.mainTerm)
				if password1 == password2 then
					local f = fs.open("/.sPhone/config/.password", "w")
					f.write(sha256.sha256(password1))
					f.close()
					term.setTextColor(colors.lime)
					visum.align("center","  Password set!",false,13)
					sleep(2)
					break
				else
					sPhone.wrongPassword = true
				end
			end
			
			local name
			
			term.setBackgroundColor(sPhone.theme["backgroundColor"])
			term.clear()
			sPhone.header("Setup")
			term.setCursorPos(1,1)
			term.setTextColor(sPhone.theme["text"])
			term.setCursorPos(2,3)
			visum.align("center","Username",false,3)
			term.setCursorPos(2,5)
			local newUsername = read()
			local f = fs.open("/.sPhone/config/username","w")
			f.write(newUsername)
			f.close()
			
			if fs.exists("/.sPhone/config/username") then
				local f = fs.open("/.sPhone/config/username","r")
				name = f.readLine()
				f.close()
			else
				name = "Guest"
			end
			term.setBackgroundColor(sPhone.theme["backgroundColor"])
			term.clear()
			sPhone.header("Setup")
			term.setCursorPos(1,1)
			term.setTextColor(sPhone.theme["text"])
			sPhone.user = name
			os.setComputerLabel(sPhone.user.."'s sPhone")
			visum.align("center","  All Set!",false,3)
			visum.align("center","  Have fun with sPhone",false,5)
			sleep(2)
			sPhone.locked = false
			sPhone.inHome = true
			sPhone.firstBoot = false
			return
		end
	end

	sPhone.lock = login
	sPhone.login = login

	local newVersion = http.get("https://raw.githubusercontent.com/BeaconNet/sPhone/master/src/version").readLine()
	
	if newVersion ~= sPhone.version then
		sPhone.newUpdate = true
	else
		sPhone.newUpdate = false
	end
	
	login()
	if sPhone.newUpdate then
		sPhone.winOk("New Update!")
	end
	home()

end
if not sPhone then
	kernel(...)
else
	print("sPhone already started")
end
