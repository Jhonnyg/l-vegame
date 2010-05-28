function love.load()
	
	-- Set the background color to soothing pink.
	love.graphics.setBackgroundColor(110, 110, 110)
	
	love.graphics.setColor(255, 255, 255, 200)
	font = love.graphics.newFont("CONSOLA.TTF", 11)--love._vera_ttf, 10)
	love.graphics.setFont(font)
	
	widgets = {}
	widgets[1] = new_button(300, 200, 200, 80, "Quit", function () love.event.push("q") end )
	widgets['inputbox'] = new_input(300, 300, 200, function () love.event.push("q") end )
	
	widgetlook = love.graphics.newImage("uilook.png")
	
	hover = 0
	
	key_buffer = ""
	bs_last = false
	bs_now = false
	bs_released = false
	
end

function love.update(dt)

	-- update all widgets
	local mx, my = love.mouse.getPosition()
	for k,w in pairs(widgets) do
		local hit = w:hittest(mx, my)
		if hit then
			hover = k
		end
		w:update(dt, hit)
	end
end

function love.draw()

	-- update 
    for k,w in pairs(widgets) do
		w:draw()
	end
	
	-- debug
	love.graphics.print(widgets['inputbox'].value, 20, 20)
end

function love.keypressed(k)
	if k == "escape" then
		love.event.push("q")
	end

	if k == "r" then
		love.filesystem.load("main.lua")()
	end
	
	if k == "backspace" then
		bs_released = true
	end
	
	if #k == 1 and string.byte(k) > 45 and string.byte(k) < 123 then
		key_buffer = key_buffer .. k
	end
	
	if k == " " then
		key_buffer = key_buffer .. " "
	end
end

function love.keyreleased(k)
	--[[if k == "backspace" then
		bs_released = true
	else
		bs_released = false
	end]]
end

function new_widget(px, py, w, h, onClicked)
	widget = {x = px, y = py, w = w, h = h, onClicked = onClicked}
	
	-- update widget
	function widget:update(dt, hit)
		self.hit = hit
	end
	
	-- draw widget
	function widget:draw()
		--[[if self.hit then
			love.graphics.setColor(0x44, 0xff, 0x44)
		else
			love.graphics.setColor(0xff, 0x44, 0x44)
		end
		love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)]]
	end
	
	-- point hittest
	function widget:hittest(mx, my)
		if mx < self.x then
			return false
		elseif mx > self.x + self.w then
			return false
		elseif my < self.y then
			return false
		elseif my > self.y + self.h then
			return false
		end
		
		return true
	end
	
	return widget
end

function new_button(px, py, w, h, label, onClicked)
	widget = new_widget(px, py, w, h, onClicked)
	widget.label = label
	
	widget.oldupdate = widget.update
	function widget:update(dt, hit)
		self:oldupdate(dt, hit)
		
		if hit and love.mouse.isDown("l") then
			self.onClicked()
		end
	end
	
	function widget:draw()
		if self.hit then
			love.graphics.setColor(0x44, 0xff, 0x44)
		else
			love.graphics.setColor(0xff, 0x44, 0x44)
		end
		
		love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
		
		love.graphics.setColor(0xee, 0xee, 0xee)
		love.graphics.print(self.label, self.x + self.w / 2 - #self.label * 3 + 1, self.y + self.h / 2 + 3 + 1)
		love.graphics.setColor(0x11, 0x11, 0x11)
		love.graphics.print(self.label, self.x + self.w / 2 - #self.label * 3, self.y + self.h / 2 + 3)
	end
	
	return widget
end


function new_input(px, py, w, onEnter)
	h = 20
	widget = new_widget(px, py, w, h, onEnter)
	widget.active = false
	widget.value = ""
	widget.max_visible = math.floor(w / 6)
	
	widget.oldupdate = widget.update
	function widget:update(dt, hit)
		self:oldupdate(dt, hit)
		
		if love.mouse.isDown("l") then
			if hit then
				self.active = true
			else
				self.active = false
			end
		end
		
		if self.active then
			-- capture input
			if love.keyboard.isDown("return") then
				self.onClicked()
			elseif bs_released then
				if #self.value > 0 then
					self.value = string.sub(self.value, 1, #self.value - 1)
				end
				bs_released = false
			else
				self.value = self.value .. key_buffer
				key_buffer = ""
			end
		end
	end
	
	function widget:draw()
		--[[if self.active then
			love.graphics.setColor(0x44, 0xff, 0x44)
		else
			love.graphics.setColor(0xff, 0x44, 0x44)
		end
		
		love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)
		]]
		love.graphics.setColor(0xff, 0xff, 0xff)
		love.graphics.draws(widgetlook, self.x, self.y, self.w, self.h)
		
		local outputstr = string.sub(self.value .. "|", -widget.max_visible)
		love.graphics.setColor(0xee, 0xee, 0xee)
		love.graphics.print(outputstr, self.x + 3, self.y + self.h / 2 + 4)
		love.graphics.setColor(0x11, 0x11, 0x11)
		love.graphics.print(outputstr, self.x + 2, self.y + self.h / 2 + 3)
	end
	
	return widget
end




