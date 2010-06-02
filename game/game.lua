require "LUBE.lua"

game = {}

is_server = false

-------------------------------------------------------------------------
-- Debugging helpers
function t_dvar(var)
  return ("'" .. tostring(var) .. "' (" .. type(var) .. ")")
end

function vec2(x,y)
  return {x = x, y = y}
end

-------------------------------------------------------------------------
-- Callback functions for LUBE
function server_messages(data_in, id)
  data = lube.bin:unpack(data_in)
  msg = data.msg
  
  if msg == "GetUID" then
    print("Sending UID")
    for i,v in pairs(netserver.clients) do
      if not (i == id) then
        netserver:send(lube.bin:pack({msg = 'NewUID', id = client_uid, ip = netserver.clients[id][1]}), i) -- Notify all other clients that a new client has connected
      else
        netserver:send(lube.bin:pack({msg = 'NewUIDLocal', id = client_uid, ip = netserver.clients[id][1]}), i) -- Notify the new client of his own id
        for tuid = 1,(client_uid-1) do
          netserver:send(lube.bin:pack({msg = 'NewUID', id = tuid, ip = netserver.clients[tuid][1]}), i) -- Notify the new client of all other/previous clients
        end
      end
    end
    client_uid = client_uid + 1
  elseif msg == "SyncVar" then
    
    -- client id
    clientid = data.id
    
    -- syncvar id and value
    varid = data.var
    value = data.value
    
    --print("Server needs to sync var: " .. t_dvar(varid) .. " with value: " .. t_dvar(value) .. " for client: " .. t_dvar(clientid))
    
    -- propagate syncvars to all other clients
    for i,v in pairs(netserver.clients) do
      if not (i == id) then
        netserver:send(data_in, i)
      end
    end
  end
end

function server_connect(data)
  print("server_connect: " .. tostring(data))
end

function server_disconnect(data)
  print("server_disconnect: " .. tostring(data))
end

function client_messages(data)
  data = lube.bin:unpack(data)
  msg = data.msg
  
  if msg == "NewUID" then
    -- A new client has connected (remote)
    -- create a client object for it
    print("New remote player (id = " .. tostring(data.id) .. ", ip = " .. tostring(data.ip) .. ").")
    remote_clients[data.id] = new_client(data.ip, true)
    
  elseif msg == "NewUIDLocal" then
    -- We are the new client that has been connected
    -- create a client object for it
    print("Connected to server as new player (id = " .. tostring(data.id) .. ", ip = " .. tostring(data.ip) .. ").")
    local_id = data.id
    local_client = new_client(data.ip, false)
  elseif msg == "SyncVar" then
    
    -- client id
    clientid = data.id
    
    -- syncvar id and value
    varid = data.var
    val = data.value
    
    --print("Client needs to sync var: " .. t_dvar(varid) .. " with value: " .. t_dvar(val) .. " for client: " .. t_dvar(clientid))
    if remote_clients[clientid] then
      remote_clients[clientid][varid] = val
    else
      print("No remote client with that id")
    end
  end
end

-------------------------------------------------------------------------
-- Client functions
function game.join_server(ip)
  is_server = false
  netclient = lube.client()
  netclient:setCallback(client_messages)
  netclient:setHandshake("Pooper")
  print("Started client: " .. tostring(netclient:connect(ip, 4632, true)))
  
  -- pack and send UID request
  netclient:send(lube.bin:pack({msg = 'GetUID'}))
end

function new_camera()
    camera = {}
    camera.lookat = {x = 0
                    ,y = 0 }
    scroll_offset = settings.size.x / 4
    
    function camera:update()
        if local_client.x < -self.lookat.x + scroll_offset then
            self.lookat.x = -local_client.x + scroll_offset
        elseif local_client.x > settings.size.x - self.lookat.x - scroll_offset then
            self.lookat.x = settings.size.x-local_client.x - scroll_offset
        end
        
    end
    
    return camera
end

-------------------------------------------------------------------------
-- Server functions
function game.start_server()
  netserver = lube.server(4632)
  netserver:setCallback(server_messages, server_connect, server_disconnect)
  netserver:setHandshake("Pooper")
  print("Started server...")
  
  -- Join new local server
  game.join_server("localhost")
  is_server = true
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

-------------------------------------------------------------------------
-- Joint Client & Server functions
function game.init()
  love.keyboard.setKeyRepeat(1, 1)
end

function game.preload()
	love.keyboard.setKeyRepeat(1)
  settings = { size = vec2(800,600), fullscreen = false, worldsize = vec2(2000,2000)}

	-- Set the background color to soothing pink.
  love.graphics.setMode(settings.size.x, settings.size.y, settings.fullscreen, true, 0)
	love.graphics.setBackgroundColor(0xff, 0xf1, 0xf7)
	
	love.graphics.setColor(255, 255, 255, 200)
	--font = love.graphics.newFont(love._vera_ttf, 10)
	--love.graphics.setFont(font)
	
  --------------
  world = love.physics.newWorld(settings.worldsize.x, settings.worldsize.x)
  world:setGravity(0, 700)
  
  -- create scenery
  scene_objects = {}
  addbox(200,200,75,75)
  addbox(50,settings.size.y-90,75,75)
  addbox(settings.size.x/2,settings.size.y-15,settings.size.x*5,15)
  
	--------------
	camera = new_camera()
  
  
  --------------
  -- Networking
  netserver = nil
  netclient = nil
  
  --------------
  client_uid = 1 -- TODO: Make this only available in the server
  remote_clients = {}
end

function game.update(dt)
        -- update world
        world:update(dt)
        -- update camera
        if local_client then
          camera:update(dt)
          local_client:update(dt)
        end
        
        -- update remote clients
        for i,v in pairs(remote_clients) do
          v:update(dt)
        end
        
        if netserver then
          netserver:update(dt)
        end
        
        if netclient then
          netclient:update(dt)
        end
end

function game.draw()
        love.graphics.translate(camera.lookat.x,camera.lookat.y)
        
        if local_client then
          local_client:draw()
        end
        
        -- draw remote clients
        for i,v in pairs(remote_clients) do
          v:draw()
        end
        
        for k,v in pairs(scene_objects) do
            v:draw()
        end
        
        love.graphics.translate(-camera.lookat.x,-camera.lookat.y)
        love.graphics.print("camera lookat (" .. camera.lookat.x .. " , " .. camera.lookat.y  .. ")",200,200)
        --love.graphics.print("client pos (" .. local_client.x .. " , " .. local_client.y  .. ")",200,210)
        --v_x,v_y = local_client.body:getLinearVelocity()
        --love.graphics.print("client x_v (" .. v_x .. " , " .. v_y  .. ")",200,220)
end

--[[
-- TODO: Move this to gui part?
function love.keypressed(k)
	if k == "escape" then
		love.event.push("q")
	end

	if k == "r" then
		love.filesystem.load("main.lua")()
	end
end]]

-------------------------------------------------------------------------
-- Classes
function new_syncvar(value)
	var = {value = value, dirty = false}
	return var
end


function new_client(name, is_remote)
	client = { is_remote = is_remote, name = name}
	client.img = love.graphics.newImage("d.75.jpg")
	
  local w = client.img:getWidth()
  local h = client.img:getHeight()
  client.properties = {velocity_limit = 500, x_force = 250, y_impulse = 50}
  client.body = love.physics.newBody(world, 0, 20,4)
  client.shape = love.physics.newRectangleShape(client.body,0,0, w, h)
  client.body:setAngularDamping(0.5)
  --client.body:setLinearDamping(0.5)
  in_air = false
        
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
	  for i,v in pairs(self.synced_vars) do
	    --if v.dirty then
	      -- var is dirty, sync it!
	      data = {msg = 'SyncVar', id = local_id, var = i, value = v.value}
	      netclient:send(lube.bin:pack(data))
	      
	      --v.dirty = false
      --end
    end
	end
	
	-- update client
	function client:update(dt)
	  if self.is_remote then
	    self.body:setX(self.x)
	    self.body:setY(self.y)
    else
      self.x = self.body:getX()
      self.y = self.body:getY()
      self:sync_vars(dt)
      self:move()
    end
	end
	
	-- draw client
	function client:draw()
		-- TODO: Draw some fancy stuff!
    love.graphics.setColor(255,255,255)
    love.graphics.draw(self.img, self.x-w/2, self.y-h/2)
    
    -- draw bounding box
    love.graphics.setColor(0,0,0)
    love.graphics.polygon("line", self.shape:getPoints())
    
    -- Draw name
    local nameoffset = -50
    love.graphics.print(self.name, self.x+1, self.y+1+nameoffset)
    love.graphics.setColor(255,255,255)
    love.graphics.print(self.name, self.x, self.y+nameoffset)
	end
        
        function client:move()
                x,y = self.body:getWorldCenter()
                v_x, v_y = self.body:getLinearVelocity()
                
                if love.keyboard.isDown("left") then
                    if v_x > -self.properties.velocity_limit then
                        self.body:applyForce(-self.properties.x_force,0,x,y)
                    end
                end
                if love.keyboard.isDown("right") then
                    if v_x < self.properties.velocity_limit then
                        self.body:applyForce(self.properties.x_force,0,x,y)
                    end
                end
                if love.keyboard.isDown("up") then
                    if v_y < self.properties.velocity_limit then
                        epsilon = 0.015
                        if v_y == 0 then
                            in_air = false
                        end
                        
                        if v_y <= 0 + epsilon and in_air == false then
                            in_air = true
                            self.body:applyImpulse(0,-self.properties.y_impulse,x,y)
                        end
                    end
                end
                
                if love.keyboard.isDown(" ") then
                    
                end
        end
	
	setmetatable(client, mt)
	
	return client
end

module("game")