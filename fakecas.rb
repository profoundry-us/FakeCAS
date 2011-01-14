require 'sinatra'
require 'rack-flash'

enable :sessions
use Rack::Flash

# Allow a user to enter their username/password
get '/login' do
  session['service'] = params['service']
  erb :login
end


# Save the username/password in the session and redirect them back to the application with the ticket
post '/login' do

  # If they pass the service, simply override the one we stored during login
  if params['service']
    session['service'] = params['service']
  end

  # If the username and password were provided, send back a ticket, otherwise redirect to the login page
  if params['username'] and params['password']
    session['username'] = params['username']
    session['password'] = params['password']

    redirect "#{session['service']}&ticket=1234567890"
  else
    redirect '/login'
  end
end


# Log a user out and clear the session
get '/logout' do
  session['username'] = nil
  session['password'] = nil

  redirect "#{params['service']}"
end


# Validate that the user logged in properly
get '/validate' do
  if params['ticket'] == '1234567890' and session['username'] == session['password']
    "yes\n#{session['username']}"
  else
    "no"
  end
end
