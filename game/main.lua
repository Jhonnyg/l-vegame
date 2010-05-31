require "LUBE.lua"

function vec2(x,y)
  tbl = {x = x, y = y}
  
  return tbl
end

is_server = false

function server_messages(data, id)
  id, data = lube.bin:unpack(data)
  
  if id == "GetUID" then
    netserver:send(lube.bin:pack({NewUID = client_uid}), id)
    client_uid = client_uid + 1
  end
end

function server_connect(data)
  print("server_connect: " .. tostring(data))
end

function server_disconnect(data)
  print("server_disconnect: " .. tostring(data))
end

function client_messages(data)
  print("client_messages: " .. tostring(data))
end

function love.load()
  love.keyboard.setKeyRepeat(1)
  settings = { size = vec2(800,600), fullscreen = false}

  -- Set the background color to soothing pink.
  love.graphics.setMode(settings.size.x, settings.size.y, settings.fullscreen, true, 0)
  love.graphics.setBackgroundColor(0xff, 0xf1, 0xf7)

  love.graphics.setColor(255, 255, 255, 200)
  font = love.graphics.newFont(love._vera_ttf, 10)
  love.graphics.setFont(font)

  --------------
  world = love.physics.newWorld(settings.size.x, settings.size.y)
  world:setGravity(0, 200)

  -- create scenery
  scene_objects = {}
  addbox(200,200,75,75)
  addbox(50,settings.size.y-90,75,75)
  addbox(settings.size.x/2,settings.size.y-15,settings.size.x,15)
  --------------
  
  
  --------------
  -- Networking
  netserver = nil
  netclient = nil
  if is_server then
    netserver = lube.server(4632)
    netserver:setCallback(server_messages, server_connect, server_disconnect)
    netserver:setHandshake("Pooper")
    --netserver:startserver(4632)
    print("Started server...")
  else
    netclient = lube.client()
    netclient:setCallback(client_messages)
    netclient:setHandshake("Pooper")
    print("Started client: " .. tostring(netclient:connect("127.0.0.1", 4632, true)))
    netclient:send(lube.bin:pack({GetUID = 1}))
  end
  
  --------------
  client_uid = 0
  remote_clients = {}
  local_client = new_client("d.75.jpg")

  clients = {}
  --clients[1] = new_client("d.75.jpg")
end

function addbox(x,y,w,h)
    local t = {}
    --t.b = ground
    t.box = { body,shape}
    t.box.body = love.physics.newBody(world, x, y)
    t.box.shape = love.physics.newRectangleShape(t.box.body, 0, 0, w,h)
    function t:draw()
        love.graphics.polygon("line", t.box.shape:getPoints())
    end

    table.insert(scene_objects, t)
end

function love.update(dt)
        -- update world
        world:update(dt)
        
        if is_server then
          netserver:update(dt)
        else
          netclient:update(dt)
        end
        
        -- update clients
	--clients[1]:update(dt)
        local_client:update(dt) 
	
end

function love.draw()
        local_client:draw()
	--clients[1]:draw()
	
	-- Debug text
	love.graphics.setColor(20, 20, 20);
	i = {0, 1, 2, 3}
	for k,v in ipairs(i) do
		love.graphics.print(local_client.x, k+100, k*20+100)
                love.graphics.print(local_client.y, k+100 + 10*#(tostring(local_client.x)), k*20+100)
	end
        
        for k,v in pairs(scene_objects) do
            v:draw()
        end
        
        love.graphics.print(local_client.body:getX() .. "," .. local_client.body:getY() ,200,200)
end

function move_client(dir,f)
    x,y = local_client.body:getWorldCenter()
    if dir == "left" then
        local_client.body:applyForce(-f,0,x,y)
    end
    if dir == "right" then
        local_client.body:applyForce(f,0,x,y)
    end
    if dir == "up" then
        local_client.body:applyForce(0,-f,x,y)
    end
end

function love.keypressed(k)
	if k == "escape" then
		love.event.push("q")
	end

	if k == "r" then
		love.filesystem.load("main.lua")()
	end
        
        move_client(k,5000)
end

-----------
-- Client object

function new_syncvar(value)
	var = {value = value, dirty = false}
	return var
end


function new_client(name)
	client = {}
	client.img = love.graphics.newImage(name)
        local w = client.img:getWidth()
        local h = client.img:getHeight()
        client.body = love.physics.newBody(world, 300, 320,4)
        client.shape = love.physics.newRectangleShape(client.body,0,0, w, h)
        client.body:setAngularDamping(0.5)
        
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
                self.x = self.body:getX()
                self.y = self.body:getY()
		self:sync_vars(dt)
	end
	
	-- draw client
	function client:draw()
		-- TODO: Draw some fancy stuff!
                love.graphics.setColor(255,255,255)
                love.graphics.draw(self.img, self.x-w/2, self.y-h/2)
                
                -- draw bounding box
                love.graphics.setColor(0,0,0)
                love.graphics.polygon("line", self.shape:getPoints())
	end
	
	setmetatable(client, mt)
	
	return client
end


