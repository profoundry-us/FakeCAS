require 'sinatra'
require 'dalli'
require 'uuidtools'

class FakeCache
  def initialize
    @cache = {}
  end

  def set(key, value)
    @cache[key] = value
  end

  def unset(key) 
    @cache[key] = nil
  end

  def get(key)
    @cache[key]
  end
end

configure do
  enable :sessions

  if ENV['RACK_ENV'] == 'production'
    CACHE = Dalli::Client.new 
  else
    CACHE = FakeCache.new
  end
end

def generate_ticket
  UUIDTools::UUID.timestamp_create.to_s
end


# Currently, if a user just hits fakecas.heroku.com, redirect them to the login page
get '/' do
 redirect '/login'
end


# Allow a user to enter their username/password
get '/login' do
  @message = nil

  if params['blanks'] == 'true'
    @message = "Please provide both a username and a password."
  end

  if params['nomatch'] == 'true'
    @message = "The username and password provided do not match."
  end

  session['service'] = params['service']
  erb :login
end


# Save the username/password in the session and redirect them back to the application with the ticket
post '/login' do

  # If they pass the service, simply override the one we stored during login
  if params['service']
    session['service'] = params['service']
  end

  # If the username and password were provided, store them in the session so they can be displayed if they
  # are invalid.
  if params['username'].nil? or params['password'].nil? or params['username'].empty? or params['password'].empty?
    redirect "/login?blanks=true&service=#{session['service']}"
  else
    session['username'] = params['username']
    session['password'] = params['password']
  end

  # If the username/password are equal, generate the ticket and redirect to the application, otherwise, make
  # them login again.
  if params['username'] == params['password']
    ticket = generate_ticket

    session['ticket'] = ticket
    CACHE.set(ticket, {
      :service => session['service'],
      :timestamp => Time.new.to_i,
      :username => params['username']
    })

    redirect "#{session['service']}?ticket=#{ticket}"
  else
    redirect "/login?nomatch=true&service=#{session['service']}"
  end

end


# Log a user out and clear the session/ticket cache
get '/logout' do
  CACHE.unset(session['ticket'])

  session['ticket'] = nil
  session['username'] = nil
  session['password'] = nil

  redirect "#{params['service']}"
end


# Validate that the user logged in properly
get '/validate' do

  if params['ticket']
    data = CACHE.get(params['ticket'])

    if Time.at(data[:timestamp]) > (Time.now - 3600) # 1 hour ago
      "yes\n#{data[:username]}"
    else
      "no"
    end
  else
    "no"
  end

end
