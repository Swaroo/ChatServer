require 'sinatra'
require 'digest'
#require 'pp' #Pretty printing ruby objects, just for debugging
require 'json'


set :server, :thin
Connections = []


#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}
Message = Struct.new(:user, :message, :created)
MessageArray = Array.new
OnlineUsers = Array.new
$HeartBeatStarted = false

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
  print UserPasswordHash
  print UserTokenHash
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
  puts(JSON.generate(message.to_h))

  Connections.each do |out|
    out << "event:Message\n" + "data:"+(JSON.generate(message.to_h))+"\n\n"
  end

  MessageArray.push(message)
  MessageArray.sort!{ |a,b| a[:created] <=> b[:created]}
  puts("MessageArray:")
  #pp MessageArray
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

  OnlineUsers.push(username)

  stream :keep_open do |out|
    #out << "event:\"Users\"\n\n" + "data:{\"hello\"}\n\n"
    Connections << out
    out << "event:Users\n" + "data:" + (JSON.generate(OnlineUsers)) + "\n\n"
    callJoin(params[:id])
    out.callback do
      Connections.delete(out)
      puts "#{username} left"
      OnlineUsers.delete(username)
      callPart(username)
      
      puts "Stream closed from #{request.ip} (now #{Connections.size} open)"
    end
  end  
end

def callPart(username)
  Connections.each do |out|
    out << "event:Part\n" + "data: " + (JSON.generate(username)) + "\n\n"
  end
end

def callJoin(id)
  if (!$HeartBeatStarted)
    $HeartBeatStarted = true
    StartHeartBeat()
  end
  username = UserTokenHash[id]
  Connections.each do |out|
      out << "event:Join\n" + "data:"+(JSON.generate({"user"=>username,"created"=>Time.now.getutc.to_i}))+"\n\n"
  end
end

def StartHeartBeat()
  heartbeat = Thread.new do
    loop do
      sleep 30
      Connections.each do |out|
        out << "event:HeartBeat\n" + "data:Just keeping you alive man.\n\n"
      end
    end
  end
  heartbeat.join  
end





#get '/stream/:id', provides: 'text/event-stream' do
#  response['Access-Control-Allow-Origin'] = 'http://localhost:3006'
#  response['Access-Control-Allow-Methods'] = "GET, POST, PUT, DELETE, OPTIONS"
#  response['Access-Control-Allow-Headers'] ="accept, authorization, origin, access-control-allow-origin"
#  sse = SSE.new(response.stream)
#  puts "entered get stream"
#  
#  begin
#    Comment.on_change do |data|
#      sse.write({name: 'Test'}, event: "Message")
#    end
#  rescue IOError
#    # Client Disconnected
#  ensure
#    sse.close
#  end
#end

