require 'sqlite3'
require 'bcrypt'

module Model
  # Retrieves the article with the specified ID from the database
  #
  # @param [Integer] id The ID of the article to retrieve
  # @return [Hash] The article data if found, otherwise nil
  def self.get_article(id)
    db = SQLite3::Database.new("db/articles.db")
    db.results_as_hash = true
    db.execute("SELECT * FROM articles WHERE id = ?", id).first
  end

  # Retrieves all articles matching the search query from the database
  #
  # @param [String] query The search query
  # @return [Array] An array of articles matching the search query
  def self.find_articles(query)
    db = SQLite3::Database.new("db/articles.db")
    db.results_as_hash = true
    db.execute("SELECT * FROM articles WHERE title LIKE ?", "%#{query}%")
  end

  # Creates a new article in the database
  #
  # @param [String] title The title of the article
  # @param [String] content The content of the article
  # @return [Boolean] True if the article was successfully created, otherwise false
  def self.create_article(title, content)
    db = SQLite3::Database.new("db/articles.db")
    db.execute("INSERT INTO articles (title, content) VALUES (?, ?)", title, content)
    true
  rescue SQLite3::Exception => e
    puts "Exception occurred: #{e}"
    false
  end

  # Updates an existing article in the database
  #
  # @param [Integer] id The ID of the article to update
  # @param [String] title The new title of the article
  # @param [String] content The new content of the article
  # @return [Boolean] True if the article was successfully updated, otherwise false
  def self.update_article(id, title, content)
    db = SQLite3::Database.new("db/articles.db")
    db.execute("UPDATE articles SET title = ?, content = ? WHERE id = ?", title, content, id)
    true
  rescue SQLite3::Exception => e
    puts "Exception occurred: #{e}"
    false
  end

  # Deletes an existing article from the database
  #
  # @param [Integer] id The ID of the article to delete
  # @return [Boolean] True if the article was successfully deleted, otherwise false
  def self.delete_article(id)
    db = SQLite3::Database.new("db/articles.db")
    db.execute("DELETE FROM articles WHERE id = ?", id)
    true
  rescue SQLite3::Exception => e
    puts "Exception occurred: #{e}"
    false
  end

  # Retrieves the user with the specified username from the database
  #
  # @param [String] username The username of the user to retrieve
  # @return [Hash] The user data if found, otherwise nil
  def self.get_user(username)
    db = SQLite3::Database.new("db/users.db")
    db.results_as_hash = true
    db.execute("SELECT * FROM users WHERE username = ?", username).first
  end

  # Registers a new user in the database
  #
  # @param [String] username The username of the new user
  # @param [String] password The password of the new user
  # @return [Boolean] True if the user was successfully registered, otherwise false
  def self.register_user(username, password)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new("db/users.db")
    db.execute("INSERT INTO users (username, password_digest) VALUES (?, ?)", username, password_digest)
    true
  rescue SQLite3::Exception => e
    puts "Exception occurred: #{e}"
    false
  end

  # Authenticates a user with the provided credentials
  #
  # @param [String] username The username of the user
  # @param [String] password The password of the user
  # @return [Integer] The ID of the authenticated user if successful, otherwise nil
  def self.authenticate_user(username, password)
    user = get_user(username)
    return nil unless user
    return nil unless BCrypt::Password.new(user['password_digest']) == password
    user['id']
  end
end
