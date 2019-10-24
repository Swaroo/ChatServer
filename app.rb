require 'sinatra'
require 'sinatra/cors'
require 'sinatra/cross_origin'
require 'digest'
require 'pp'


set :protection, false

set :allow_origin, "*"
set :allow_methods, "GET,HEAD,POST,DELETE, OPTIONS"
#set :allow_headers, "content-type, if-modified-since, Access-Control-Allow-Origin, Authorization"
set :allow_headers, "*"
set :expose_headers, "location, link"


#headers['Access-Control-Allow-Origin'] = '*'
#headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
#headers['Access-Control-Request-Method'] = '*'
#headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'


#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}
Message = Struct.new(:name, :msg, :post_time)

before do
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "POST"
    response.headers["Access-Control-Allow-Headers"] = "origin, x-requested-with, content-type, authorization, accept, access-control-allow-origin"
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
  puts "\nusername : "
  puts username

  puts "\npassword: "
  puts password

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

post '/message' do
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
  return 201
end
