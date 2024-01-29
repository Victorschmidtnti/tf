require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'



enable :seassions


get('/hemsida') do
    slim(:hemsida)
end
