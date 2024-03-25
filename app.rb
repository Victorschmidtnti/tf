require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

#fixa behörighet gör if satser 
#fixa inenr join med user-type där en användare kan välja fler muskelgrupper och en muskelgrupp kan väljas av flera användare.
#fixa yardoc
enable :sessions



get('/')  do
    slim(:start, layout: :login_layout)
end 
  
get('/showlogin') do
    slim(:login, layout: :login_layout)
    #slim(:login)
end
  
post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/user.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    password_digest = result["password"] # Rättar till variabelnamnet här
    id = result["id"]
    x = result["role"]
    if BCrypt::Password.new(password_digest) == password # Jämför med det hashade lösenordet
        session[:user_id] = result["id"]
       session[:role_value] = x
      redirect('/start_inlogg')
    else
      "Fel lösenord"
    end
end
  
get('/guest_log') do
    session[:user_id] = nil 
    session[:role_value] = 0 
    slim(:inloggad)
end
get('/start_inlogg') do
    p session[:role_value]
    slim(:inloggad)
end
    
  
post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password==password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new("db/user.db") 
      if username == "admin" && password == "admin"
        role = 2 
        session[:role_value] = 2
      else
        session[:role_value] = 1
        role = 1
      end
      db.execute("INSERT INTO user (username,password,role) VALUES (?,?,?)",username,password_digest,role)
      redirect('/')
    else
      "Lösenorden matchar inte tyvärr"
    end
  
end






get('/gymlog') do 
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM gymlog WHERE \"user-id\" = ?",session[:user_id])
    
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
    exercises = params[:exercises]
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO gymlog (dag, exercises, \"user-id\") VALUES (?,?,?)" ,dag, exercises, session[:user_id])
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


get('/exercises/new') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM type") 
    slim(:"exercises/new")
  end
  

post('/exercises/new') do 
    exercises = params[:exercises]
    type_id = params[:"type-id"].to_i 
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
