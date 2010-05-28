function love.load()
	
	-- The amazing music.
	--music = love.audio.newMusic("prondisk.xm")
	
	-- The various images used.
	--body = love.graphics.newImage("body.png")
	--ear = love.graphics.newImage("ear.png")
	--face = love.graphics.newImage("face.png")
	--logo = love.graphics.newImage("love.png")
	--cloud = love.graphics.newImage("cloud_plain.png")

	-- Set the background color to soothing pink.
	love.graphics.setBackgroundColor(0xff, 0xf1, 0xf7)
	
	-- Spawn some clouds.
	--for i=1,5 do
	--	spawn_cloud(math.random(-100, 900), math.random(-100, 700), 80 + math.random(0, 50))
	--end
	
	love.graphics.setColor(255, 255, 255, 200)
	love.graphics.setColorMode("modulate")
	
	--love.audio.play(music, 0)
	
	--font = love.graphics.newFont("ARIAL.TTF", 12)
	font = love.graphics.newFont(love._vera_ttf, 10)
	love.graphics.setFont(font)
	
	--------------
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

	--love.graphics.draw(logo, 400, 380, 0, 1, 1, 128, 64)
	
	--for k, c in ipairs(clouds) do
	--	love.graphics.draw(cloud, c.x, c.y)
	--end
	
	--nekochan:render()
	
	clients[1]:draw()
	
	-- Debug text
	love.graphics.setColor(20, 20, 20);
	i = {0, 1, 2, 3}
	for k,v in ipairs(i) do
		love.graphics.print(clients[1].x, k*10+100, k*20+100)
	end
end

function love.keypressed(k)
	if k == "escape" then
		love.event.push("q")
	end

	if k == "r" then
		love.filesystem.load("main.lua")()
	end
end

-----------
-- Client object


function new_client()
	client = {}
	
	-- metatable
	mt = {}
	function mt:__index(id)
		return self.synced_vars[id]
	end
	setmetatable(client, mt)
	
	-- variables that should be synced via the network
	client.synced_vars = {x = 0, y = 0}
	
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
	end
	
	return client
end


