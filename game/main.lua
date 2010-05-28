function love.load()
	love.keyboard.setKeyRepeat(1)

	-- Set the background color to soothing pink.
	love.graphics.setBackgroundColor(0xff, 0xf1, 0xf7)
	
	love.graphics.setColor(255, 255, 255, 200)
	font = love.graphics.newFont(love._vera_ttf, 10)
	love.graphics.setFont(font)
	
	--------------
	
	remote_clients = {}
	local_client = new_client()
	
	clients = {}
	clients[1] = new_client()
	
end

function love.update(dt)
	--try_spawn_cloud(dt)
	
	--nekochan:update(dt)
	
	-- Update clouds.
	--for k, c in ipairs(clouds) do
	--	c.x = c.x + c.s * dt
	--end
	
	clients[1]:update(dt)
	
end

function love.draw()
        local_client:draw()
	clients[1]:draw()
	
	-- Debug text
	love.graphics.setColor(20, 20, 20);
	i = {0, 1, 2, 3}
	for k,v in ipairs(i) do
		love.graphics.print(local_client.x, k+100, k*20+100)
                love.graphics.print(local_client.y, k+100 + 10*#(tostring(local_client.x)), k*20+100)
	end
end

function love.keypressed(k)
	if k == "escape" then
		love.event.push("q")
	end

	if k == "r" then
		love.filesystem.load("main.lua")()
	end
	
	-- control our local client
	if k == "left" then
		local_client.x = local_client.x - 10
	elseif k == "right" then
		local_client.x = local_client.x + 10
	end
	
	if k == "up" then
		local_client.y = local_client.y + 10
	elseif k == "down" then
		local_client.y = local_client.y - 10
	end
end

-----------
-- Client object

function new_syncvar(value)
	var = {value = value, dirty = false}
	return var
end


function new_client()
	client = {}
	client.body = love.graphics.newImage("banana.jpg")
        
	-- metatable
	mt = {}
	function mt:__index(id)
		return self.synced_vars[id].value
	end
	function mt:__newindex(id, val)
		self.synced_vars[id].dirty = true
		self.synced_vars[id].value = val
	end
	
	
	-- variables that should be synced via the network
	client.synced_vars = {x = new_syncvar(0),
	                      y = new_syncvar(0)}
	
	-- sync variables via LUBE
	function client:sync_vars(dt)
		-- TODO: MAKE IT SYNC! LOL
	end
	
	-- update client
	function client:update(dt)
		self:sync_vars(dt)
	end
	
	-- draw client
	function client:draw()
		-- TODO: Draw some fancy stuff!
                love.graphics.setColor(255,255,255)
                love.graphics.draw(body, client.x, client.y,0,0.25)
	end
	
	setmetatable(client, mt)
	
	return client
end


