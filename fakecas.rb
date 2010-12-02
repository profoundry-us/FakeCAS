require 'sinatra'

get '/login' do
  redirect "#{params['service']}&ticket=1234567890"
end

get '/logout' do
  redirect "#{params['service']}"
end

get '/validate' do
  if params['ticket'] == '1234567890' and not params['pleaseFail']
    "yes\n#{params['username']}"
  else
    "no"
  end
end
