require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'


enable :sessions


# Root route for the web application, shows the start page
get('/')  do
    slim(:start, layout: :login_layout)
end 
# Shows the login form
get('/showlogin') do
    slim(:login, layout: :login_layout)
end
# Handles login
post('/login') do
    username = params[:username]
    password = params[:password]
    if username.nil? || username.empty? || password.nil? || password.empty?
        @message = "Användarnamn och lösenord måste anges"
        return slim(:login, layout: :login_layout)
    end
    db = SQLite3::Database.new("db/user.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    password_digest = result["password"] 
    id = result["id"]
    x = result["role"]
    if result.nil?
        @message = "Användarnamnet finns inte"
        return slim(:login, layout: :login_layout)
    end
    if BCrypt::Password.new(password_digest) == password # Jämför med det hashade lösenordet
        session[:user_id] = result["id"]
       session[:role_value] = x
      redirect('/start_inlogg')
    else
      @message = "Fel lösenord"
      return slim(:login, layout: :login_layout)
    end
end
# guest login
get('/guest_log') do
    session[:user_id] = nil 
    session[:role_value] = 0 
    slim(:inloggad)
end
# Start after login
get('/start_inlogg') do
    slim(:inloggad)
end
    
# Handles registration of new users
post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    if username.nil? || username.empty? || password.nil? || password.empty?
        @message = "Användarnamn och lösenord måste anges"
        return slim(:start, layout: :login_layout)
    end
    db = SQLite3::Database.new("db/user.db")
    existing_user = db.execute("SELECT COUNT(*) FROM user WHERE username = ?", username).first[0]
    if existing_user > 0
        @message = "Användarnamnet är upptaget"
        return slim(:start, layout: :login_layout)
    end
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
        @message = "Lösenorden matchar inte tyvärr"
        return slim(:start, layout: :login_layout)
    end
  
end





# Shows list of workout logs
get('/gymlog') do 
    if session[:role_value]==1    
        db = SQLite3::Database.new("db/user.db")  
        db.results_as_hash = true
        @result = db.execute("SELECT * FROM gymlog WHERE \"user-id\" = ?",session[:user_id])
        slim(:"gymlog/index")
    else
        slim(:"gymlog/index")
    end
end
# Handles deletion of workout logs
post('/gymlog/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("DELETE FROM gymlog WHERE id = ?",id)
    redirect('/gymlog')
end

# Shows form for creating new workout log
get('/gymlog/new') do
    slim(:"gymlog/new") 
end
# Handles creation of new workout log
post('/gymlog/new') do 
    dag = params[:dag]
    exercises = params[:exercises]
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO gymlog (dag, exercises, \"user-id\") VALUES (?,?,?)" ,dag, exercises, session[:user_id])
    redirect('/gymlog')
  
end

# Shows form for editing workout log
get('/gymlog/:id/edit') do
    id=params[:id].to_i
    db = SQLite3::Database.new("db/user.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM gymlog WHERE id=?",id).first
    slim(:"gymlog/edit")

end
# Handles updating workout log
post('/gymlog/:id/update') do
    id=params[:id].to_i
    dag=params[:dag]
    exercises=params[:exercises]
    db = SQLite3::Database.new("db/user.db")
    db.execute("UPDATE gymlog SET dag=?,exercises=? WHERE id = ?",dag,exercises,id)
    redirect('/gymlog')
end
# Shows list of workout users
get('/workout_users') do
     db = SQLite3::Database.new("db/user.db")
     @result = db.execute("SELECT username FROM user INNER JOIN gymlog ON user.id = gymlog.\"user-id\";")
     @usernames = @result.map(&:first)
     slim(:"number/index")
end
# Shows list of musclegroups
get('/type') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM type")
    slim(:"type/index2")
end
# Shows list of exercises for a musclegroup
get('/index2/:type_off') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    type_off=params[:type_off].to_i
    @result = db.execute("SELECT * FROM exercises WHERE \"type-id\" = ?", type_off)
    slim(:"exercises/index3")
end
# Handles deletion of exercises
post('/exercises/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("DELETE FROM exercises WHERE id = ?",id)
    redirect('/type')
end

# Shows form for creating new exercise
get('/exercises/new') do
    if session[:role_value]==2
        db = SQLite3::Database.new("db/user.db")  
        db.results_as_hash = true
        @result = db.execute("SELECT * FROM type") 
        slim(:"exercises/new")
    end
  end
  
# Handles creation of new exercise
post('/exercises/new') do 
    exercises = params[:exercises]
    type_id = params[:"type-id"].to_i 
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO exercises (exercises, \"type-id\") VALUES (?, ?)", exercises, type_id)
    redirect('/type')
end
  
# Shows form for editing exercise
get('/exercises/:id/edit') do
    id=params[:id].to_i
    db = SQLite3::Database.new("db/user.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM exercises WHERE id=?",id).first
    slim(:"exercises/edit")
end
# Handles updating exercise
post('/exercises/:id/update') do
    id=params[:id].to_i
    exercises=params[:exercises]
    db = SQLite3::Database.new("db/user.db")
    db.execute("UPDATE exercises SET exercises=? WHERE id = ?",exercises,id)
    redirect('/type')
end
