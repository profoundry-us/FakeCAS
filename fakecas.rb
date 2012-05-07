require 'sinatra'
require 'uuidtools'

class FakeCache
  def initialize
    @cache = {}
  end

  def set(key, value)
    @cache[key] = value
  end

  def delete(key) 
    @cache[key] = nil
  end

  def get(key)
    @cache[key]
  end
end

configure do
  enable :sessions

  if ENV['RACK_ENV'] == 'production'
    require 'dalli'
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


# Allow a user to enter the requested username
get '/login' do
  @message = nil

  if params['blanks'] == 'true'
    @message = "Please provide the username of the user you wish to log in as."
  end

  session['service'] = params['service']
  erb :login
end


# Save the username in the session and redirect them back to the application with the ticket
post '/login' do

  # If they pass the service, simply override the one we stored during login
  if params['service']
    session['service'] = params['service']
  end


  # If the username is not provided or is empty, redirect back to the login page and let the user know
  if params['username'].nil? or params['username'].empty?
    redirect "/login?blanks=true&service=#{session['service']}"
  else
    session['username'] = params['username']
  end


  # Generate and store the ticket!
  ticket = generate_ticket

  session['ticket'] = ticket
  CACHE.set(ticket, {
    :service => session['service'],
    :timestamp => Time.new.to_i,
    :username => params['username']
  })

  if session['service'].include? '?'
    redirect "#{session['service']}&ticket=#{ticket}"
  else
    redirect "#{session['service']}?ticket=#{ticket}"
  end

end


# Log a user out and clear the session/ticket cache
get '/logout' do
  CACHE.delete(session['ticket'])

  session['ticket'] = nil
  session['username'] = nil

	service = params['service']

	if service.nil? or service.empty?
		service = params['url']
	end

  redirect "#{service}"
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
