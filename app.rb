require 'sinatra'
require 'sinatra/cors'
require 'sinatra/cross_origin'
require 'digest'


set :protection, false

set :allow_origin, "http://localhost:3006"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type, if-modified-since, Access-Control-Allow-Origin"
set :expose_headers, "location, link"


#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}

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
  UserTokenHash[username] = digest
  print UserPasswordHash
  print UserTokenHash
  status = 201
  headers = {"content-type" => "application/json"}
  body = {"token" => digest}.to_json
  [status,headers,body]
end
