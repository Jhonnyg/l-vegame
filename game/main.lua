require "game.lua" -- 

menu = {}

-- Menu actions
-- TODO: Move these actions to a better place? :S
menu.action = {}
function menu.action.join_server(ip)
  game.join_server(widgets.serverip.value)
  change_gamestate("game")
end

function menu.action.start_server()
  game.start_server()
  change_gamestate("game")
end

function menu.preload()
	-- Set the background color to soothing pink.
	love.graphics.setBackgroundColor(110, 110, 110)
	
	love.graphics.setColor(255, 255, 255, 200)
	font = love.graphics.newFont("data/ProggySmall.ttf", 15)--love._vera_ttf, 10)
	love.graphics.setFont(font)
	
	----------------------------------------------------------------------------
	-- Setup widget look and feel
	widgetlook = love.graphics.newImage("uilook.png")
  widgetlook:setFilter( "linear", "linear" )
  look = { button = {}, input = {} }
  look.button.topleft = love.graphics.newQuad(0, 0, 5, 5, 256, 256)
  look.button.topright = love.graphics.newQuad(7, 0, 5, 5, 256, 256)
  look.button.top = love.graphics.newQuad(8, 0, 1, 5, 256, 256)
  look.button.bottom = love.graphics.newQuad(8, 7, 1, 5, 256, 256)
  look.button.bottomleft = love.graphics.newQuad(0, 7, 5, 5, 256, 256)
  look.button.bottomright = love.graphics.newQuad(7, 7, 5, 5, 256, 256)
  look.button.left = love.graphics.newQuad(0, 8, 5, 1, 256, 256)
  look.button.right = love.graphics.newQuad(7, 8, 5, 1, 256, 256)
  look.button.bg = love.graphics.newQuad(254, 0, 1, 255, 256, 256)
  look.button.bginv = love.graphics.newQuad(254, 255, 1, -255, 256, 256)

  function look.button:render(x, y, w, h, push, label)
    love.graphics.setColor(255, 255, 255)
    if not push then
        love.graphics.drawq( widgetlook, self.bg, x+1, y+1, 0, w-2, 1.0/256.0 * (h-2), 0, 0)
    else
        love.graphics.drawq( widgetlook, self.bginv, x+1, y+1, 0, w-2, -1.0/256.0 * (h-2), 0, 0)
    end

    love.graphics.drawq( widgetlook, self.topleft, x, y, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.topright, x+w-5, y, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottomleft, x, y+h-5, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottomright, x+w-5, y+h-5, 0, 1, 1, 0, 0)

    love.graphics.drawq( widgetlook, self.top, x+5, y, 0, w-10, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottom, x+5, y+h-5, 0, w-10, 1, 0, 0)

    love.graphics.drawq( widgetlook, self.right, x+w-5, y+5, 0, 1, h-10, 0, 0)
    love.graphics.drawq( widgetlook, self.left, x, y+5, 0, 1, h-10, 0, 0)

    -- Label
    love.graphics.setColor(0x11, 0x11, 0x11)
  	love.graphics.print(label, x + w / 2 - #label * 3 + 1, y + h / 2 + 3 + 1)
  	love.graphics.setColor(0xee, 0xee, 0xee)
  	love.graphics.print(label, x + w / 2 - #label * 3, y + h / 2 + 3)
  end
  
  look.input.topleft = love.graphics.newQuad(0, 0, 5, 5, 256, 256)
  look.input.topright = love.graphics.newQuad(7, 0, 5, 5, 256, 256)
  look.input.top = love.graphics.newQuad(8, 0, 1, 5, 256, 256)
  look.input.bottom = love.graphics.newQuad(8, 7, 1, 5, 256, 256)
  look.input.bottomleft = love.graphics.newQuad(0, 7, 5, 5, 256, 256)
  look.input.bottomright = love.graphics.newQuad(7, 7, 5, 5, 256, 256)
  look.input.left = love.graphics.newQuad(0, 8, 5, 1, 256, 256)
  look.input.right = love.graphics.newQuad(7, 8, 5, 1, 256, 256)
  look.input.bg = love.graphics.newQuad(254, 255, 1, -255, 256, 256)
  
  function look.input:render(x, y, w, h, value)
    love.graphics.setColor(80, 80, 80)
    --love.graphics.drawq( widgetlook, self.bg, x+1, y+1, 0, w-2, -1.0/256.0 * (h-2), 0, 0)
    love.graphics.rectangle("fill", x+1, y+1, w-2, h-2)

    love.graphics.setColor(255, 255, 255)
    love.graphics.drawq( widgetlook, self.topleft, x, y, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.topright, x+w-5, y, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottomleft, x, y+h-5, 0, 1, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottomright, x+w-5, y+h-5, 0, 1, 1, 0, 0)

    love.graphics.drawq( widgetlook, self.top, x+5, y, 0, w-10, 1, 0, 0)
    love.graphics.drawq( widgetlook, self.bottom, x+5, y+h-5, 0, w-10, 1, 0, 0)

    love.graphics.drawq( widgetlook, self.right, x+w-5, y+5, 0, 1, h-10, 0, 0)
    love.graphics.drawq( widgetlook, self.left, x, y+5, 0, 1, h-10, 0, 0)

    -- Value
    love.graphics.setColor(0x11, 0x11, 0x11)
		love.graphics.print(value, x + 4, y + h / 2 + 4)
		love.graphics.setColor(0xee, 0xee, 0xee)
		love.graphics.print(value, x + 3, y + h / 2 + 3)
  end
  
  -- End of Look and Feel
  ---------------------------------------------------------------------
  
  
  -- Setup menu widgets
	widgets = {}
	widgets['quit'] = new_button(10, 10, 80, 24, "Quit", function () love.event.push("q") end )
	widgets['start_server'] = new_button(300, 200, 100, 24, "Start server", menu.action.start_server )
	widgets['serverip'] = new_input(300, 300, 200, "localhost", function () menu.action.join_server(widgets.serverip.value) end )
	widgets['join_server'] = new_button(300, 340, 100, 24, "Join server", function () menu.action.join_server(widgets.serverip.value) end )
	
	-- general GUI state holders
	hover = 0 -- id of current widget the mouse is hovering (0 = none)
	key_buffer = "" -- buffer for all text input widgets
	bs_last = false
	bs_now = false
	bs_released = false

end

function menu.update(dt)
  -- update all widgets
	local mx, my = love.mouse.getPosition()
	for k,w in pairs(widgets) do
		local hit = w:hittest(mx, my)
		if hit then
			hover = k
		end
		w:update(dt, hit)
	end
	
	-- clear key buffer
	key_buffer = ""
end

function menu.draw()
	love.graphics.setBackgroundColor(110, 110, 110)
	love.graphics.setColor(255, 255, 255, 200)
	
  -- update 
  for k,w in pairs(widgets) do
		w:draw()
	end
	
	-- debug
	--love.graphics.print(widgets['inputbox'].value, 20, 20)
end

function menu.init()
  love.keyboard.setKeyRepeat(400, 80)
end

function change_gamestate(new_state)
  gs = new_state
  gamestates[gs].init()
end

function love.load()
  
  -- application/game state
	gamestates = {
	  menu = {
	    preload = menu.preload,
	    init    = menu.init,
	    update  = menu.update,
	    draw    = menu.draw
	  },
	  game = {
	    preload = game.preload,
	    init    = game.init,
	    update  = game.update,
	    draw    = game.draw
	  }
	}
	gs = nil
  
  for state,v in pairs(gamestates) do
    gamestates[state].preload()
  end
  
  change_gamestate("menu")
end

function love.update(dt)
  gamestates[gs].update(dt)
end

function love.draw()
  gamestates[gs].draw()
end

function love.keypressed(k)
	if k == "escape" then
		--love.event.push("q")
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
	widget.pushed = false
	
	widget.oldupdate = widget.update
	function widget:update(dt, hit)
		self:oldupdate(dt, hit)
		
		if hit and (not love.mouse.isDown("l")) and self.pushed then
		  self.onClicked()
	  end
		
		if hit and love.mouse.isDown("l") then
		  self.pushed = true
		else
		  self.pushed = false
	  end
	end
	
	function widget:draw()
        look.button:render(self.x, self.y, self.w, self.h, self.pushed, self.label)
	end
	
	return widget
end


function new_input(px, py, w, value, onEnter)
	h = 20
	widget = new_widget(px, py, w, h, onEnter)
	widget.active = false
	widget.value = value
	widget.outputstr = value
	widget.max_visible = math.max(0, math.floor(w / 7) - 1)
	
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
			
			self.outputstr = string.sub(self.value .. "|", -self.max_visible)
		end
	end
	
	function widget:draw()
		look.input:render(self.x, self.y, self.w, self.h, self.outputstr)
	end
	
	return widget
end




