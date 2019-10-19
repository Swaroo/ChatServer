require 'sinatra'
require 'sinatra/cors'
require 'digest'
set :allow_methods, "localhost:3006"
set :allow_methods, "GET,HEAD,POST"
set :allow_headers, "content-type"

#Global variables start with a capital letter
UserPasswordHash = {}
UserTokenHash = {}

# Added this just for testing
get '/' do
  status 200
end

post '/login' do
  params.to_s
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
  UserTokenHash[username] = digest
  print UserPasswordHash
  print UserTokenHash
  status = 201
  headers = {"content-type" => "application/json"}
  body = {"token" => digest}.to_json
  [status,headers,body]
end
