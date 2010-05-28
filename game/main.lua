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
	
end

function love.update(dt)
	--try_spawn_cloud(dt)
	
	--nekochan:update(dt)
	
	-- Update clouds.
	--for k, c in ipairs(clouds) do
	--	c.x = c.x + c.s * dt
	--end
	
end

function love.draw()

	--love.graphics.draw(logo, 400, 380, 0, 1, 1, 128, 64)
	
	--for k, c in ipairs(clouds) do
	--	love.graphics.draw(cloud, c.x, c.y)
	--end
	
	--nekochan:render()
	
end

function love.keypressed(k)
	if k == "r" then
		love.filesystem.load("main.lua")()
	end
end

