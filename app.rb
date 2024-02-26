require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'



enable :sessions



get('/')  do
  slim(:start)
end 

get('/gymlog') do 
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM gymlog")
    
    slim(:"gymlog/index")
end

post('/gymlog/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("DELETE FROM gymlog WHERE id = ?",id)
    redirect('/gymlog')
end

get('/gymlog/new') do
    slim(:"gymlog/new") 
end

post('/gymlog/new') do 
    dag = params[:dag]
    exercises = params[:exercises].to_i
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO gymlog (dag, exercises) VALUES (?,?)" ,dag, exercises)
    redirect('/gymlog')
end


get('/gymlog/:id/edit') do
    id=params[:id].to_i
    db = SQLite3::Database.new("db/user.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM gymlog WHERE id=?",id).first
    slim(:"gymlog/edit")

end

post('/gymlog/:id/update') do
    id=params[:id].to_i
    dag=params[:dag]
    exercises=params[:exercises]
    db = SQLite3::Database.new("db/user.db")
    db.execute("UPDATE gymlog SET dag=?,exercises=? WHERE id = ?",dag,exercises,id)
    redirect('/gymlog')
end

get('/type') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM type")
    slim(:"type/index2")
end

get('/index2/:type_off') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    type_off=params[:type_off].to_i
    @result = db.execute("SELECT * FROM exercises WHERE \"type-id\" = ?", type_off)
    slim(:"exercises/index3")
end

post('/exercises/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("DELETE FROM exercises WHERE id = ?",id)
    redirect('/type')
end

# Route för att visa formuläret för att lägga till en ny övning
get('/exercises/new') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM type") # Hämta alla muskelgrupper för dropdown-menyn
    slim(:"exercises/new")
  end
  
  # Route för att ta emot formulärdata och lägga till en ny övning
  post('/exercises/new') do 
    exercises = params[:exercises]
    type_id = params[:type_id].to_i # Det valda värdet från dropdown-menyn
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO exercises (exercises, \"type-id\") VALUES (?, ?)", exercises, type_id)
    redirect('/type')
  end
  

get('/exercises/:id/edit') do
    id=params[:id].to_i
    db = SQLite3::Database.new("db/user.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM exercises WHERE id=?",id).first
    slim(:"exercises/edit")
end

post('/exercises/:id/update') do
    id=params[:id].to_i
    exercises=params[:exercises]
    db = SQLite3::Database.new("db/user.db")
    db.execute("UPDATE exercises SET exercises=? WHERE id = ?",exercises,id)
    redirect('/type')
end
