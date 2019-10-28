require 'sinatra'
require 'digest'
require 'pp' #Pretty printing ruby objects, just for debugging
require 'json'
require 'sinatra/sse'
require 'securerandom'

set :server, :thin
Connections = {}


#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}
Disconnect = Struct.new(:created)
Join = Struct.new(:user, :created)
Message = Struct.new(:user, :message, :created)
Part = Struct.new(:user, :created)
ServerStatus = Struct.new(:status, :created)
Users = Struct.new(:created, :users)

EventHistory = {}

OnlineUsers = Array.new
$HeartBeatStarted = false


# first event is always a server status
initial_server_status = ServerStatus.new("Server was initialized", Time.now.getutc.to_i)
eventId = SecureRandom.hex
EventHistory[eventId] = "id:"+eventId+"\nevent:ServerStatus\n" + "data: " + (JSON.generate(initial_server_status.to_h)) + "\n\n"

# send new event every hour
status_thread = Thread.new do
  hours_alive = 0
  while(1)
    sleep 3600 #try 10 for debugging
    hours_alive += 1
    callServerStatus(hours_alive)
  end
end

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "*"
    halt 200
  end
end

post '/login' do
  response['Access-Control-Allow-Origin'] = '*'

  if params["password"].nil? || params["username"].nil?
    return 422
  elsif params["password"] == "" || params["username"] == ""
    return 422
  end
  #username and password are not null or empty at this stage
  username = params["username"]
  password = params["password"]

  #the user doesn't exist in our system
  if UserPasswordHash[username].nil?
    UserPasswordHash[username] = password

  #user already exists, validate the password
  else
    if UserPasswordHash[username] != password
      return 403
    end
  end

  #Now send a token back to user
  digest = Digest::SHA256.hexdigest(username+ "|"+ password)
  UserTokenHash[digest] = username
  status = 201
  headers = {"content-type" => "application/json"}
  body = {"token" => digest}.to_json

  [status,headers,body]
end

post '/message', provides: 'text/event-stream' do
  response['Access-Control-Allow-Origin'] = '*'
  response['Access-Control-Allow-Methods'] = "GET, POST, PUT, DELETE, OPTIONS"
  response['Access-Control-Allow-Headers'] ="accept, authorization, origin, access-control-allow-origin"

  header_data = request.env["HTTP_AUTHORIZATION"]
  if header_data.nil? || header_data.empty? || params["message"].nil? || params["message"].empty?
    return 422
  end
  to_be_validated_token = header_data[7, header_data.length] #strip Bearer from the string
  puts(to_be_validated_token)

  name = UserTokenHash[to_be_validated_token]
  if name.nil? || name.empty?
    return 403
  end
  msg = params["message"]
  message = Message.new(name, msg, Time.now.getutc.to_i)

  eventId = SecureRandom.hex
  payload = "id:"+eventId+"\nevent:Message\n" + "data:"+(JSON.generate(message.to_h))+"\n\n"
  EventHistory[eventId] = payload

  Connections.each do |user, out|
    out << payload
  end  
  
  # EventHistory.push(message)
  # EventHistory.sort!{ |a,b| a[:created] <=> b[:created]}

  while (EventHistory.length > 100)
    EventHistory.shift()
  end

  return 201
end

get '/stream/:id', provides: 'text/event-stream' do |token|
  response['Access-Control-Allow-Origin'] = '*'
  response['Access-Control-Allow-Methods'] = "GET, POST, PUT, DELETE, OPTIONS"
  response['Access-Control-Allow-Headers'] ="accept, authorization, origin, access-control-allow-origin"

  puts "token:"
  pp token

  username = UserTokenHash[token]
  puts "username:"
  pp username  

  # return 403 if token is not valid (no username)
  if username.nil?
    status 403
    return
  end

  # If http_last_event_id is present, the client lost the connection and retrying again, send the events that they missed
  # if !(request.env['HTTP_LAST_EVENT_ID'].nil?)
  #   sendRemainingEvents(request.env['HTTP_LAST_EVENT_ID'], username)
  #   return
  # end

  stream :keep_open do |out|
    # If user already logged in, disconnect first connection. Send event history to 2nd connection
    if Connections.key?(username)
      callDisconnect(username)

      #update Connections hash with new output stream
      Connections[username] = out

      # users_event = Users.new(Time.now.getutc.to_i, OnlineUsers)
      # out << "id:"+SecureRandom.hex+"\nevent:Users\n" + "data:" + (JSON.generate(users_event.to_h)) + "\n\n"
      sendEventHistory(out)
    else 
      # store username in array and connections hash
      OnlineUsers.push(username)
      Connections[username] = out

      # send Users event
      users_event = Users.new(Time.now.getutc.to_i, OnlineUsers)
      out << "id:"+SecureRandom.hex+"\nevent:Users\n" + "data:" + (JSON.generate(users_event.to_h)) + "\n\n"

      #EventHistory.push(users_event)
      #EventHistory.sort!{ |a,b| a[:created] <=> b[:created]}

      sendEventHistory(out)
      # Send Join event on self (only first time)
      callJoin(params[:id])
    end

    # when client disconnects, remove from list of users and connections hash
    out.callback do   
      puts "#{username} left"
      OnlineUsers.delete(username)
      Connections.delete(username) # remove first so Part is not sent to self
      # send Part event
      callPart(username)
      puts "Stream closed from #{request.ip} (now #{Connections.size} open)"
    end
  end
end

def callPart(username)
  part_thread = Thread.new do
    
    part_event = Part.new(username, Time.now.getutc.to_i)
    # EventHistory.push(part_event)
    # EventHistory.sort!{ |a,b| a[:created] <=> b[:created]}

    eventId = SecureRandom.hex
    payload = "id:"+eventId+"\nevent:Part\n" + "data:"+(JSON.generate(part_event.to_h))+"\n\n"
    EventHistory[eventId] = payload

    # send Part event to remaining users
    Connections.each do |user, out|
      out << payload
    end
  end
end

def callJoin(id)
  username = UserTokenHash[id]
    
  join_event = Join.new(username, Time.now.getutc.to_i)
  # EventHistory.push(join_event)
  # EventHistory.sort!{ |a,b| a[:created] <=> b[:created]}

  eventId = SecureRandom.hex
  payload = "id:"+eventId+"\nevent:Join\n" + "data:"+(JSON.generate(join_event.to_h))+"\n\n"
  EventHistory[eventId] = payload
  
  # send Join event to all users
  Connections.each do |user, out|      
      out << payload
  end

  if (!$HeartBeatStarted)
    $HeartBeatStarted = true
    StartHeartBeat()
  end  
end

def callDisconnect(username)
  # get output stream corresponding to logged in user
  out = Connections[username]

  # force logged in user to disconnect first instance
  disconnect_event = Disconnect.new(Time.now.getutc.to_i)
  out << "id:"+SecureRandom.hex+"\nevent:Disconnect\n" + "data:"+(JSON.generate(disconnect_event.to_h))+"\n\n"
end

def StartHeartBeat()
  heartbeat = Thread.new do
    loop do
      sleep 30
      Connections.each do |user, out|
        out << "event:HeartBeat\n" + "data:Just keeping you alive man.\n\n"
      end
    end
  end
  heartbeat.join  
end

def callServerStatus(hours_alive)
    # send ServerStatus to 
    puts "call server status"
    status_event = ServerStatus.new("Server uptime: " + hours_alive.to_s + "hours", Time.now.getutc.to_i)
    # EventHistory.push(status_event)
    # EventHistory.sort!{ |a,b| a[:created] <=> b[:created]}

    eventId = SecureRandom.hex
    payload = "id:"+eventId+"\nevent:ServerStatus\n" + "data:"+(JSON.generate(status_event.to_h))+"\n\n"
    EventHistory[eventId] = payload

    while EventHistory.length > 100
      EventHistory.shift()
    end

    Connections.each do |user, out|
      out << payload
    end
end

def sendEventHistory(out)
  EventHistory.each do |key, value|
    out << value
  end
end

def sendRemainingEvents(id, username)
  puts "Username - ",username
  puts "Event Id - ", id
  puts "Event History - "
  pp EventHistory
  puts "Connections - "
  puts Connections
  found = false
  EventHistory.each do |key, value|
    if found || id == key
      if id == key
        found = true
      else
        Connections[username] << value
      end
    end
  end
end





