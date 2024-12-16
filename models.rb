# frozen_string_literal: true

# --- User ---

def find_user(id)
  rows = DB.execute <<~SQL, [id]
    SELECT id, name, email, created_at, updated_at
      FROM users
     WHERE id = ?
  SQL

  rows[0]
end

def find_user_by_email(email)
  rows = DB.execute <<~SQL, [email]
    SELECT id, name, email, created_at, updated_at
      FROM users
     WHERE email = ?
  SQL

  rows[0]
end

def find_auth_user(id)
  rows = DB.execute <<~SQL, [id]
    SELECT id, name, email, password, created_at, updated_at
      FROM users
     WHERE id = ?
  SQL

  rows[0]
end

def find_auth_user_by_email(email)
  rows = DB.execute <<~SQL, [email]
    SELECT id, name, email, password, created_at, updated_at
      FROM users
     WHERE email = ?
  SQL

  rows[0]
end

def create_user(name, email, password)
  hashed = BCrypt::Password.create password

  rows = DB.execute <<~SQL, [name, email, hashed, now, now]
    INSERT INTO users (name, email, password, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?)
      RETURNING id
  SQL

  rows[0]['id']
end

def update_user(id, name, email)
  rows = DB.execute <<~SQL, [name, email, now, id]
       UPDATE users
          SET name = ?,
              email = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def update_user_password(id, password)
  hashed = BCrypt::Password.create password

  rows = DB.execute <<~SQL, [hashed, now, id]
       UPDATE users
          SET password = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def email_exists?(email)
  rows = DB.execute <<~SQL, [email]
    SELECT id
      FROM users
     WHERE email = ?
  SQL

  rows[0]
end

def username_exists?(username)
  rows = DB.execute <<~SQL, [username]
    SELECT id
      FROM profiles
     WHERE username = ?
  SQL

  rows[0]
end

def existing_email_not_mine?(email, my_id)
  rows = DB.execute <<~SQL, [email, my_id]
    SELECT id
      FROM users
     WHERE email = ? AND id != ?
  SQL

  rows[0]
end

def authenticated?(hash, guess)
  hashed = BCrypt::Password.new hash
  hashed == guess
end

def validate_user(email)
  [invalid_email?(email)].compact
end

def validate_signup(email, username, password)
  [
    invalid_email?(email),
    invalid_username?(username),
    invalid_password?(password),
  ].compact
end

def validate_change_password(new_password, confirm_password)
  [
    invalid_password?(new_password),
    if confirm_password != new_password then 'Passwords must match.' end
  ].compact
end

# --- Link ---

def find_link(id)
  rows = DB.execute <<~SQL, [id]
    SELECT id, profile_id, title, href, created_at, updated_at
      FROM links
     WHERE id = ?
  SQL

  rows[0]
end

def find_all_public_links(username)
  DB.execute <<~SQL, [username]
        SELECT l.title, l.href, p.username
          FROM links l
    INNER JOIN profiles p ON p.id = l.profile_id
         WHERE p.username = ?
  SQL
end

def find_all_links_by_profile_id(profile_id)
  DB.execute <<~SQL, [profile_id]
    SELECT id, profile_id, title, href, created_at, updated_at
      FROM links
     WHERE profile_id = ?
  SQL
end

def create_link(profile_id, title, href)
  rows = DB.execute <<~SQL, [profile_id, title, href, now, now]
    INSERT INTO links (profile_id, title, href, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?)
      RETURNING id
  SQL

  rows[0]['id']
end

def update_link(id, title, href)
  rows = DB.execute <<~SQL, [title, href, now, id]
       UPDATE links
          SET title = ?,
              href = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def delete_link(id)
  DB.execute <<~SQL, [id]
    DELETE FROM links
          WHERE id = ?
  SQL
end

def validate_link(href)
  [invalid_url?(href)].compact
end

# --- Profile ---

def find_profile(id)
  rows = DB.execute <<~SQL, [id]
    SELECT id, user_id, title, username, colour, bg_colour, image_url,
           image_alt, is_live, css, created_at, updated_at
      FROM profiles
     WHERE id = ?
  SQL

  rows[0]
end

def find_profile_by_user_id(user_id)
  rows = DB.execute <<~SQL, [user_id]
    SELECT id, user_id, title, username, colour, bg_colour, image_url,
           image_alt, is_live, css, created_at, updated_at
      FROM profiles
     WHERE user_id = ?
  SQL

  rows[0]
end

def find_public_profile(username)
  rows = DB.execute <<~SQL, [username]
    SELECT id, title, username, colour, bg_colour, image_url, image_alt,
           is_live, css
      FROM profiles
     WHERE username = ?
  SQL

  rows[0]
end

def create_profile(user_id, username)
  rows = DB.execute <<~SQL, [user_id, username, now, now]
    INSERT INTO profiles (user_id, username, created_at, updated_at)
         VALUES (?, ?, ?, ?)
      RETURNING id
  SQL

  rows[0]['id']
end

def update_profile(id, title, colour, bg_colour, image_alt, css)
  rows = DB.execute <<~SQL, [title, colour, bg_colour, image_alt, css, now, id]
       UPDATE profiles
          SET title = ?,
              colour = ?,
              bg_colour = ?,
              image_alt = ?,
              css = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def update_profile_image(id, filename, tempfile)
  userdata_path = make_userdata_path filename, 'profile', id
  FileUtils.cp tempfile.path, userdata_path

  rows = DB.execute <<~SQL, [userdata_path, now, id]
       UPDATE profiles
          SET image_url = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def update_profile_live(id)
  rows = DB.execute <<~SQL, [now, id]
       UPDATE profiles
          SET is_live = 1,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def show_public_profile?(is_live, profile_id, session_profile_id)
  if is_live == 1
    true
  else
    session_profile_id && session_profile_id == profile_id
  end
end

def validate_profile(image_url, colour, bg_colour)
  [
    if image_url then invalid_image?(image_url) end,
    if colour then invalid_colour?(colour) end,
    if bg_colour then invalid_colour?(bg_colour) end,
  ].compact
end

# --- Integration ---

def find_integration(id)
  rows = DB.execute <<~SQL, [id]
    SELECT id, profile_id, mailchimp_subscribe_url, created_at, updated_at
      FROM integrations
     WHERE id = ?
  SQL

  rows[0]
end

def find_public_integration(username)
  rows = DB.execute <<~SQL, [username]
        SELECT i.mailchimp_subscribe_url
          FROM integrations i
    INNER JOIN profiles p ON i.profile_id = p.id
         WHERE p.username = ?
  SQL

  rows[0]
end

def create_integration(profile_id)
  rows = DB.execute <<~SQL, [profile_id, now, now]
    INSERT INTO integrations (profile_id, created_at, updated_at)
         VALUES (?, ?, ?)
      RETURNING id
  SQL

  rows[0]['id']
end

def update_integration(id, subscribe_url)
  rows = DB.execute <<~SQL, [subscribe_url, now, id]
       UPDATE integrations
          SET mailchimp_subscribe_url = ?,
              updated_at = ?
        WHERE id = ?
    RETURNING id
  SQL

  rows[0]['id']
end

def get_subscribe_url(api_key)
  region = api_key.split('-')[1]
  lists_url = URI("https://#{region}.api.mailchimp.com/3.0/lists")
  headers = { 'Authorization': "Bearer #{api_key}" }

  response = Net::HTTP.get(lists_url, headers)
  url = JSON.parse(response)['lists'][0]['subscribe_url_long']
  parts = url.split('?')

  "#{parts[0]}/post?#{parts[1]}"
end

# --- Password reset request ---

def find_pw_reset_request(uuid)
  rows = DB.execute <<~SQL, [uuid]
    SELECT id, uuid, user_id, created_at, updated_at
      FROM pw_reset_requests
     WHERE uuid = ?
  SQL

  rows[0]
end

def create_pw_reset_request(user_id, email)
  uuid = SecureRandom.uuid

  DB.execute <<~SQL, [uuid, user_id, now, now]
    INSERT INTO pw_reset_requests (uuid, user_id, created_at, updated_at)
         VALUES (?, ?, ?, ?)
  SQL

  send_forgot_pw_email(uuid, email)
end

def expired_pw_reset_request?(uuid, hours)
  rows = DB.execute <<~SQL, [uuid]
    SELECT created_at
      FROM pw_reset_requests
     WHERE uuid = ?
  SQL

  created_at = rows[0]['created_at']

  diff = DateTime.now.to_time.to_i - DateTime.parse(created_at).to_time.to_i
  diff > 3600 * hours
end

def send_forgot_pw_email(uuid, email)
  link = "https://#{ENV['HOSTNAME']}/forgot-password/#{uuid}"

  message = <<~EMAIL
    From: #{ENV['MAILER']}
    To: #{email}
    Subject: Teatree -- Forgot password

    Click this link to reset your password <#{link}>
  EMAIL

  Net::SMTP.start(
    ENV['SMTP_HOST'],
    ENV['SMTP_PORT'],
    helo: ENV['HOSTNAME'],
    user: ENV['SMTP_USER'],
    secret: ENV['SMTP_PASS']
  ) do |smtp|
    smtp.send_message(message, ENV['MAILER'], email)
  end
end
