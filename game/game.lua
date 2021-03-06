require "LUBE.lua"

game = {}

is_server = false
ping_timeout = 10



-------------------------------------------------------------------------
-- Debugging helpers
function t_dvar(var)
  return ("'" .. tostring(var) .. "' (" .. type(var) .. ")")
end

function vec2(x,y)
  return {x = x, y = y}
end

debug_log = {}
debug_log.count = 0
debug_log.max = 10

function add_log(msg)
  -- shift back old
  for i = 1,(debug_log.count-1) do
    if (debug_log[i + 1]) then
      debug_log[i] = debug_log[i + 1]
    end
  end
  
  -- add new msg
  debug_log.count = debug_log.count + 1
  if (debug_log.count > debug_log.max) then
    debug_log.count = debug_log.max
  end
  debug_log[debug_log.count] = msg
  
  -- output to stdout also
  print(msg)
end

function print_log()
  for i = 1,(debug_log.count) do
    if debug_log[i] then
      love.graphics.print(debug_log[i], 5, 5 + i * 8)
    end
  end
end

-------------------------------------------------------------------------
-- Callback functions for LUBE
function server_messages(data_in, id)
  data = lube.bin:unpack(data_in)
  msg = data.msg
  
  --print("Number of active clients: " .. tostring(netserver:number_of_clients()))
  
  if msg == "GetUID" then
    
    client_uid = id
    
    for i,v in pairs(netserver.clients) do
      if not (i == id) then
        netserver:send(lube.bin:pack({msg = 'NewUID', id = client_uid, ip = netserver.clients[id][1], is_host = data.is_host}), i) -- Notify all other clients that a new client has connected
      else
        netserver:send(lube.bin:pack({msg = 'NewUIDLocal', id = client_uid, ip = netserver.clients[id][1], is_host = data.is_host}), i) -- Notify the new client of his own id
        --for tuid = 1,(client_uid-1) do
        for tuid,tval in pairs(server_data.clients) do
          netserver:send(lube.bin:pack({msg = 'NewUID', id = tuid, ip = tval.ip, is_host = tval.is_host}), i) -- Notify the new client of all other/previous clients
        end
      end
    end
    
    -- add client info to server data
    server_data.clients[client_uid] = {ip = netserver.clients[id][1], is_host = data.is_host}
    
    --client_uid = client_uid + 1
  elseif msg == "ClientDisconnect" then
    clientid = data.id
    
    -- send notification to all users that client with id has left
    server_data.clients[clientid] = nil
    netserver.clients[clientid] = nil

    for i,v in pairs(server_data.clients) do
      netserver:send(data_in, i)
    end
    
  elseif msg == "SyncVar" then
    
    -- client id
    clientid = data.id
    
    -- syncvar id and value
    varid = data.var
    value = data.value
    
    
    if netserver.clients[clientid] == nil then
      print("Can't propagate a non known client! (" .. tostring(clientid) .. ")")
      return
    end
    
    -- propagate syncvars to all other clients
    for i,v in pairs(netserver.clients) do
    --for i,v in pairs(server_data.clients) do
      if not (i == id) then
        netserver:send(data_in, i)
      end
    end
    
  elseif msg == "ClientInput" then
    -- Handle input sent from clients
    if (id == local_id) then
      -- input from remote clients
      local_client:handle_input(data.input)
    else
      -- input from our own client
      remote_clients[id]:handle_input(data.input)
    end
  end
end

function server_connect(data)
  print("server_connect: " .. tostring(data))
end

function server_disconnect(data)
  print("server_disconnect: " .. tostring(data))
  
  server_data.clients[data] = nil
  disconnect_data = lube.bin:pack({msg = "ClientDisconnect",
                                   id = data,
                                   reason = "Client pinged out!"})
                                   
  for i,v in pairs(server_data.clients) do
    netserver:send(disconnect_data, i)
  end
end

function client_messages(data)
  data = lube.bin:unpack(data)
  msg = data.msg
  
  if msg == "NewUID" then
    -- A new client has connected (remote)
    -- create a client object for it
    add_log("New remote player (id = " .. tostring(data.id) .. ", ip = " .. tostring(data.ip) .. ", is_host = " .. tostring(data.is_host) .. ").")
    remote_clients[data.id] = new_client(data.ip, data.id, true, data.is_host)
    
  elseif msg == "NewUIDLocal" then
    -- We are the new client that has been connected
    -- create a client object for it
    add_log("Connected to server as new player (id = " .. tostring(data.id) .. ", ip = " .. tostring(data.ip) .. ", is_host = " .. tostring(data.is_host) .. ").")
    local_id = data.id
    local_client = new_client(data.ip, data.id, false, data.is_host)
    
  elseif msg == "SyncVar" then
    
    -- client id
    clientid = data.id
    
    -- syncvar id and value
    varid = data.var
    val = data.value
    packid = data.packid
    
    --print("Client needs to sync var: " .. t_dvar(varid) .. " with value: " .. t_dvar(val) .. " for client: " .. t_dvar(clientid))
    if remote_clients[clientid] then
      remote_clients[clientid]:update_syncvar(varid, val, packid)--[varid] = val
    elseif clientid == local_id then
      local_client:update_syncvar(varid, val, packid)--[varid] = val
    else
      print("No remote client with that id")
    end
    
  elseif msg == "ClientDisconnect" then
    add_log("A client has disconnected (id = " .. tostring(data.id) .. " reason = " .. tostring(data.reason) .. ")")
    
    -- Remove client from our list of remote clients
    client_disconnected(data.id)
  end
end

-------------------------------------------------------------------------
-- Client functions
function game.join_server(ip)
  --is_server = false
  netclient = lube.client()
  netclient:setCallback(client_messages)
  netclient:setHandshake("Pooper")
  netclient:setPing(true, ping_timeout, "hello")
  print("Started client: " .. tostring(netclient:connect(ip, 4632, true)))
  
  -- pack and send UID request
  netclient:send(lube.bin:pack({msg = 'GetUID', is_host = is_server}))
end

-- Called when a client disconnects
function client_disconnected(id)
  if remote_clients[id] then
    remote_clients[id].body = nil
  end
  remote_clients[id] = nil
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
        
        if local_client.y < -self.lookat.y + scroll_offset then
            self.lookat.y = -local_client.y + scroll_offset
        elseif local_client.y > settings.size.y - self.lookat.y - scroll_offset then
            self.lookat.y = settings.size.y-local_client.y - scroll_offset
        end
            
        
    end
    
    return camera
end

-------------------------------------------------------------------------
-- Server functions
server_data = {}
server_data.clients = {}

function game.start_server()
  is_server = true
  netserver = lube.server(4632)
  netserver:setCallback(server_messages, server_connect, server_disconnect)
  netserver:setHandshake("Pooper")
  netserver:setPing(true, ping_timeout, "hello")
  print("Started server...")
  
  -- Join new local server
  game.join_server("localhost")
  
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
  
  -- setup camera
	camera = new_camera()
end

function game.preload()
  --------------
  -- Networking
  netserver = nil
  netclient = nil
  
  --------------
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
        
        love.graphics.setColor(0,0,0)
        for k,v in pairs(scene_objects) do
          v:draw()
        end
        
        
        -- Debug print
        love.graphics.setColor(0,0,0)
        love.graphics.translate(-camera.lookat.x,-camera.lookat.y)
        love.graphics.print("camera lookat (" .. camera.lookat.x .. " , " .. camera.lookat.y  .. ")",200,200)
        print_log()
        
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
	var = {value = value, dirty = false, packid = 0}
	return var
end


function new_client(name, client_id, is_remote, is_host)
	client = { id = client_id, is_remote = is_remote, name = name, is_host = is_host }
	client.img = love.graphics.newImage("d.75.jpg")
	
  local w = client.img:getWidth()
  local h = client.img:getHeight()
  client.properties = {velocity_limit = 500, x_force = 250, y_impulse = 50}
  
  -- only add physics if we are the server
  if is_server then
    client.body = love.physics.newBody(world, 0, 20,4)
    client.shape = love.physics.newRectangleShape(client.body,0,0, w, h)
    client.body:setAngularDamping(0.5)
    --client.body:setLinearDamping(0.5)
    in_air = false
  end
        
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
	                      
	function client:update_syncvar(id, val, packid)
	  if packid > self.synced_vars[id].packid then
	    self.synced_vars[id].value = val
	    self.synced_vars[id].packid = packid
    else
      add_log("Got old sync data! (packid = " .. tostring(packid) .. " compared to " .. tostring(self.synced_vars[id].packid) .. ")")
    end
  end
	
  function client:clean_quit()
    data = {msg = "ClientDisconnect", id = self.id, reason = "Player left game."}
    netclient:send(lube.bin:pack(data))
  end
        
	-- sync variables via LUBE
	function client:sync_vars(dt)
	  for i,v in pairs(self.synced_vars) do
	    if v.dirty then
	      -- var is dirty, sync it!
	      self.synced_vars[i].packid = self.synced_vars[i].packid + 1
	      data = {msg = 'SyncVar', id = self.id, var = i, value = v.value, packid = self.synced_vars[i].packid}
	      netclient:send(lube.bin:pack(data))
	      
	      v.dirty = false
      end
    end
	end
	
	-- update client
	function client:update(dt)
    -- only the server should update positions etc
    if is_server then
      local x = self.body:getX()
      local y = self.body:getY()
      if not (x == self.x) then
        self.x = x
      end
      
      if not (y == self.y) then
        self.y = y
      end
      
      self:sync_vars(dt)
    end
    
    -- if this is the local client, update movement via input
    if not self.is_remote then
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
    if is_server then
      love.graphics.polygon("line", self.shape:getPoints())
    end
    
    -- Draw name
    local nameoffset = -50
    local rendername = self.name
    if self.is_host then
      rendername = rendername .. " (HOST)"
    end
    love.graphics.print(rendername, self.x+1, self.y+1+nameoffset)
    love.graphics.setColor(255,255,255)
    love.graphics.print(rendername, self.x, self.y+nameoffset)
	end
        
  function client:move()
    -- TODO: This should be moved to game.keypushed or something like that (ie. to a state action/function).
    if love.keyboard.isDown("escape") then
        self:clean_quit()
        love.event.push("q")
    end
    
    if love.keyboard.isDown("left") then
        netclient:send(lube.bin:pack({msg = "ClientInput", input = "left"}))
    end
    
    if love.keyboard.isDown("right") then
        netclient:send(lube.bin:pack({msg = "ClientInput", input = "right"}))
    end
    
    if love.keyboard.isDown("up") then
        netclient:send(lube.bin:pack({msg = "ClientInput", input = "up"}))
    end
    
  end
  
  function client:handle_input(input)
    x,y = self.body:getWorldCenter()
    v_x, v_y = self.body:getLinearVelocity()

    if input == "left" then
        if v_x > -self.properties.velocity_limit then
            self.body:applyForce(-self.properties.x_force,0,x,y)
        end
    end
    if input == "right" then
        if v_x < self.properties.velocity_limit then
            self.body:applyForce(self.properties.x_force,0,x,y)
        end
    end
    if input == "up" then
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
  end
	
	setmetatable(client, mt)
	
	return client
end

module("game")