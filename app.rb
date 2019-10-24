require 'sinatra'
require 'digest'
require 'pp' #Pretty printing ruby objects, just for debugging


set :server, :thin
connections = []






#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}
Message = Struct.new(:name, :msg, :post_time)
MessageArray = Array.new

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "*"
    puts("Reached options")
    halt 200
  end
end

# Added this just for testing
get '/' do
  status 200
end

post '/login' do
  response['Access-Control-Allow-Origin'] = '*'
  puts "post/login"

  puts params.to_s


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
  puts(message)

  MessageArray.push(message)
  MessageArray.sort!{ |a,b| a[:post_time] <=> b[:post_time]}
  puts("MessageArray:")
  pp MessageArray

  stream :keep_open do |out|
    out << "HEllo"
  end

  return 201
end

get '/stream/:id', provides: 'text/event-stream' do
  response['Access-Control-Allow-Origin'] = '*'
  response['Access-Control-Allow-Methods'] = "GET, POST, PUT, DELETE, OPTIONS"
  response['Access-Control-Allow-Headers'] ="accept, authorization, origin, access-control-allow-origin"
  
  puts "get /stream"
  stream :keep_open do |out|
    payload = {"data" => "this is some data", event => "Message", id => "1234"}
    puts payload.to_json
    out << payload.to_json
  end
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

