require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model/model.rb'

enable :sessions
include Model # Wat dis?

# Authentication Filter
#

before do
    unless ['/showlogin', '/login', '/guest_log', '/', '/users/new'].include?(request.path_info) || session[:user_id]
        @message = "Du måste logga in för att få tillgång till den här sidan"
        redirect('/showlogin')
    end
end


# Root route for the web application, shows the start page
#
get('/')  do
    slim(:start, layout: :login_layout)
end 
# Shows the login form
#
get('/showlogin') do
    session[:login_attempts] ||= 0
    session[:last_login_attempt_time] ||= Time.now - 61
    slim(:login, layout: :login_layout)
end
# Handles login and redirects to '/start_inlogg'
#
# @param [string] username, the name of the user
# @param [string] password, the users password

post('/login') do
    username = params[:username]
    password = params[:password]
    if Time.now - session[:last_login_attempt_time] < 60 && session[:login_attempts] >= 3
        @message = "För många inloggningsförsök. Vänligen försök igen om en minut."
        return slim(:login, layout: :login_layout)
    end
      session[:login_attempts] += 1
      session[:last_login_attempt_time] = Time.now
    if username.nil? || username.empty? || password.nil? || password.empty?
        @message = "Användarnamn och lösenord måste anges"
        return slim(:login, layout: :login_layout)
    end
    db = SQLite3::Database.new("db/user.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM user WHERE username = ?", username).first
    if result.nil?
        @message = "Användarnamnet finns inte"
        return slim(:login, layout: :login_layout)
    end
    password_digest = result["password"] 
    id = result["id"]
    x = result["role"]
    if BCrypt::Password.new(password_digest) == password 
        session[:user_id] = result["id"]
       session[:role_value] = x
      redirect('/start_inlogg')
    else
      @message = "Fel lösenord"
      return slim(:login, layout: :login_layout)
    end
end
# Guest login
#
get('/guest_log') do
    session[:user_id] = nil 
    session[:role_value] = 0 
    slim(:inloggad)
end
# Start after login
#
get('/start_inlogg') do
    slim(:inloggad)
end
    
# Handles registration of new users and redirects to  redirect('/') 
#
# @params[string] username, the name of the user
# @params[string] password, the users password
# @param [String] repeat-password, The repeated password
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
# get('/gymlog') do 
#     if session[:role_value]==1    
#         db = SQLite3::Database.new("db/user.db")  
#         db.results_as_hash = true
#         @result = db.execute("SELECT * FROM gymlog WHERE \"user-id\" = ?",session[:user_id])
#         slim(:"gymlog/index")
#     else
#         slim(:"gymlog/index")
#     end
# end
# # Handles deletion of workout logs
# post('/gymlog/:id/delete') do
#     id = params[:id].to_i
#     db = SQLite3::Database.new("db/user.db")  
#     db.execute("DELETE FROM gymlog WHERE id = ?",id)
#     redirect('/gymlog')
# end

# # Shows form for creating new workout log
# get('/gymlog/new') do
#     slim(:"gymlog/new") 
# end
# # Handles creation of new workout log
# post('/gymlog/new') do 
#     dag = params[:dag]
#     exercises = params[:exercises]
#     db = SQLite3::Database.new("db/user.db") 
#     db.execute("INSERT INTO gymlog (dag, exercises, \"user-id\") VALUES (?,?,?)" ,dag, exercises, session[:user_id])
#     redirect('/gymlog')
  
# end

# # Shows form for editing workout log
# get('/gymlog/:id/edit') do
#     id=params[:id].to_i
#     db = SQLite3::Database.new("db/user.db")
#     db.results_as_hash = true
#     @result = db.execute("SELECT * FROM gymlog WHERE id=?",id).first
#     slim(:"gymlog/edit")

# end
# Handles updating workout log
# post('/gymlog/:id/update') do
#     id=params[:id].to_i
#     dag=params[:dag]
#     exercises=params[:exercises]
#     db = SQLite3::Database.new("db/user.db")
#     db.execute("UPDATE gymlog SET dag=?,exercises=? WHERE id = ?",dag,exercises,id)
#     redirect('/gymlog')
# end

# Handles creation of new workout log and associating it with the current user and redirects to '/gymlog'
#
# @params[string] dag, the day
# @params[string] exercises, the exercises you have done
post('/gymlog') do 
    dag = params[:dag]
    exercises = params[:exercises]
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO gymlog (dag, exercises, \"user-id\") VALUES (?,?,?)" ,dag, exercises, session[:user_id])

    # Insert into user_gymlog table to associate the new gymlog with the current user
    gymlog_id = db.last_insert_row_id
    db.execute("INSERT INTO user_gymlog (user_id, gymlog_id) VALUES (?, ?)", session[:user_id], gymlog_id)

    redirect('/gymlog')
end
# New route to handel creation of new gymlog
#
get('/gymlog/new') do
   slim(:"gymlog/new") 
end
# Shows list of workout logs for the current user
#
get('/gymlog') do 
    if session[:role_value]==1    
        db = SQLite3::Database.new("db/user.db")  
        db.results_as_hash = true
        # Using INNER JOIN to fetch gymlogs associated with the current user
        @result = db.execute("SELECT g.* FROM gymlog g INNER JOIN user_gymlog ug ON g.id = ug.gymlog_id WHERE ug.user_id = ?", session[:user_id])
        slim(:"gymlog/index")
    else
        slim(:"gymlog/index")
    end
end

# New route to handle associating gymlogs with users redirects to'/gymlog'
#
# @param[interger] :id, the id of the relation
post('/gymlog/:id/associate') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("INSERT INTO user_gymlog (user_id, gymlog_id) VALUES (?, ?)", session[:user_id], id)
    redirect('/gymlog')
end
# New route to edit the gymlog
#
# @param[interger] :id, the id of the gymlog you want to edit
 get('/gymlog/:id/edit') do
     id=params[:id].to_i
     db = SQLite3::Database.new("db/user.db")
     db.results_as_hash = true
     @result = db.execute("SELECT * FROM gymlog WHERE id=?",id).first
     slim(:"gymlog/edit")
end
# Updates an existing gymlog and redirects to '/gymlog'
#
# @param[interger] :id, the id of the gymlog you want to edit
# @param[string] dag, the day you want to change
# @param[string] exercises, the exercises you want to change
 post('/gymlog/:id/update') do
         id=params[:id].to_i
         dag=params[:dag]
         exercises=params[:exercises]
         db = SQLite3::Database.new("db/user.db")
         owner_id_str = db.execute("SELECT \"user-id\" FROM gymlog WHERE id = ?", id).first.to_s
         owner_id = owner_id_str.match(/\d+/)[0].to_i if owner_id_str
        if session[:user_id] && session[:user_id] == owner_id
            db.execute("UPDATE gymlog SET dag=?,exercises=? WHERE id = ?",dag,exercises,id)
        end
          
          redirect('/gymlog')      
        
end
# New route to handle deleting gymlogs redirects to '/gymlog'
#
# @param[id] :id, the id of the gymlog you delete
post('/gymlog/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    owner_id_str = db.execute("SELECT \"user-id\" FROM gymlog WHERE id = ?", id).first.to_s
    owner_id = owner_id_str.match(/\d+/)[0].to_i if owner_id_str
    if session[:user_id] && session[:user_id] == owner_id
      db.execute("DELETE FROM gymlog WHERE id = ?", id)
    end
    
    redirect('/gymlog')
  end
  
  
  


# Route that shows list of workout users
#
get('/workout_users') do
     db = SQLite3::Database.new("db/user.db")
     @result = db.execute("SELECT username FROM user INNER JOIN gymlog ON user.id = gymlog.\"user-id\";")
     @usernames = @result.map(&:first)
     slim(:"number/index")
end
# Route that shows list of musclegroups
#
get('/type') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM type")
    slim(:"type/index2")
end
# Route that shows list of exercises for a musclegroup
#
get('/index2/:type_off') do
    db = SQLite3::Database.new("db/user.db")  
    db.results_as_hash = true
    type_off=params[:type_off].to_i
    @result = db.execute("SELECT * FROM exercises WHERE \"type-id\" = ?", type_off)
    slim(:"exercises/index3")
end
# Handles deletion of exercises and redirects to '/type'
#
# @param[interger] :id, the id for the deleted ecercises
post('/exercises/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/user.db")  
    db.execute("DELETE FROM exercises WHERE id = ?",id)
    redirect('/type')
end

# Shows form for creating new exercise
#
get('/exercises/new') do
    if session[:role_value]==2
        db = SQLite3::Database.new("db/user.db")  
        db.results_as_hash = true
        @result = db.execute("SELECT * FROM type") 
        slim(:"exercises/new")
    end
  end
  
# Handles creation of new exercise and redirects to '/type'
#
# @params[interger] exercises, create new exercise
# @param[interger] :type_id, the id of what muscle group

post('/exercises') do 
    exercises = params[:exercises]
    type_id = params[:"type-id"].to_i 
    db = SQLite3::Database.new("db/user.db") 
    db.execute("INSERT INTO exercises (exercises, \"type-id\") VALUES (?, ?)", exercises, type_id)
    redirect('/type')
end
  
# Shows form for editing exercise
#
# @param[interger] :id, the id of the exercises
get('/exercises/:id/edit') do
    id=params[:id].to_i
    db = SQLite3::Database.new("db/user.db")
    db.results_as_hash = true
    @result = db.execute("SELECT * FROM exercises WHERE id=?",id).first
    slim(:"exercises/edit")
end
# Handles updating exercise and redirects to '/type'
#
# @param[interger] :id, the id of the exercises
# @param[string] exercises, the name of the exercise
post('/exercises/:id/update') do
    id=params[:id].to_i
    exercises=params[:exercises]
    db = SQLite3::Database.new("db/user.db")
    db.execute("UPDATE exercises SET exercises=? WHERE id = ?",exercises,id)
    redirect('/type')
end
