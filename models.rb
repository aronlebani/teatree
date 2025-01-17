# frozen_string_literal: true

def find_user(id)
	DB.execute(<<~SQL, [id]).first
		SELECT id, name, email, created_at, updated_at
		FROM users
		WHERE id = ?
	SQL
end

def find_user_by_email(email)
	DB.execute(<<~SQL, [email]).first
		SELECT id, name, email, created_at, updated_at
		FROM users
		WHERE email = ?
	SQL
end

def find_auth_user(id)
	DB.execute(<<~SQL, [id]).first
		SELECT id, name, email, password, created_at, updated_at
		FROM users
		WHERE id = ?
	SQL
end

def find_auth_user_by_email(email)
	DB.execute(<<~SQL, [email]).first
		SELECT id, name, email, password, created_at, updated_at
		FROM users
		WHERE email = ?
	SQL
end

def create_user(name, email, password)
	hashed = BCrypt::Password.create password

	DB.execute(<<~SQL, [name, email, hashed, now, now]).first['id']
		INSERT INTO users (name, email, password, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?)
		RETURNING id
	SQL
end

def update_user(id, name, email)
	DB.execute(<<~SQL, [name, email, now, id]).first['id']
		UPDATE users
		SET name = ?, email = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def update_user_password(id, password)
	hashed = BCrypt::Password.create password

	DB.execute(<<~SQL, [hashed, now, id]).first['id']
		UPDATE users
		SET password = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def email_exists?(email)
	DB.execute(<<~SQL, [email]).first
		SELECT id
		FROM users
		WHERE email = ?
	SQL
end

def username_exists?(username)
	DB.execute(<<~SQL, [username]).first
		SELECT id
		FROM profiles
		WHERE username = ?
	SQL
end

def existing_email_not_mine?(email, my_id)
	DB.execute(<<~SQL, [email, my_id]).first
		SELECT id
		FROM users
		WHERE email = ? AND id != ?
	SQL
end

def authenticated?(hash, guess)
	hashed = BCrypt::Password.new hash
	hashed == guess
end

def validate_user(email)
	combine_validators(valid_email?(email))
end

def validate_signup(email, username, password)
	combine_validators(
		valid_email?(email),
		valid_username?(username),
		valid_password?(password)
	)
end

def validate_change_password(new_password, confirm_password)
	combine_validators(	
		valid_password?(new_password),
		confirm_password == new_password || 'Passwords must match'
	)
end

def find_link(id)
	DB.execute(<<~SQL, [id]).first
		SELECT id, profile_id, title, href, created_at, updated_at
		FROM links
		WHERE id = ?
	SQL
end

def find_all_public_links(username)
	DB.execute(<<~SQL, [username])
		SELECT l.title, l.href, p.username
		FROM links l
		INNER JOIN profiles p ON p.id = l.profile_id
		WHERE p.username = ?
	SQL
end

def find_all_links_by_profile_id(profile_id)
	DB.execute(<<~SQL, [profile_id])
		SELECT id, profile_id, title, href, created_at, updated_at
		FROM links
		WHERE profile_id = ?
	SQL
end

def create_link(profile_id, title, href)
	DB.execute(<<~SQL, [profile_id, title, href, now, now]).first['id']
		INSERT INTO links (profile_id, title, href, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?)
		RETURNING id
	SQL
end

def update_link(id, title, href)
	DB.execute(<<~SQL, [title, href, now, id]).first['id']
		UPDATE links
		SET title = ?, href = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def delete_link(id)
	DB.execute(<<~SQL, [id])
		DELETE FROM links
		WHERE id = ?
	SQL
end

def validate_link(href)
	combine_validators(valid_url?(href))
end

def find_profile(id)
	DB.execute(<<~SQL, [id]).first
		SELECT id, user_id, title, username, colour, bg_colour, image_url,
			image_alt, is_live, css, created_at, updated_at
		FROM profiles
		WHERE id = ?
	SQL
end

def find_profile_by_user_id(user_id)
	DB.execute(<<~SQL, [user_id]).first
		SELECT id, user_id, title, username, colour, bg_colour, image_url,
			image_alt, is_live, css, created_at, updated_at
		FROM profiles
		WHERE user_id = ?
	SQL
end

def find_public_profile(username)
	DB.execute(<<~SQL, [username]).first
		SELECT id, title, username, colour, bg_colour, image_url, image_alt,
			is_live, css
		FROM profiles
		WHERE username = ?
	SQL
end

def create_profile(user_id, username)
	DB.execute(<<~SQL, [user_id, username, now, now]).first['id']
		INSERT INTO profiles (user_id, username, created_at, updated_at)
		VALUES (?, ?, ?, ?)
		RETURNING id
	SQL
end

def update_profile(id, title, colour, bg_colour, image_alt, css)
	DB.execute(<<~SQL, [title, colour, bg_colour, image_alt, css, now, id]).first['id']
		UPDATE profiles
		SET title = ?, colour = ?, bg_colour = ?, image_alt = ?, css = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def update_profile_image(id, filename, tempfile)
	userdata_filename = make_userdata_filename(filename, 'profile', id)
	FileUtils.cp(tempfile.path, File.join(ENV.fetch('USERDATA_DIR'), userdata_filename))

	DB.execute(<<~SQL, [userdata_filename, now, id]).first['id']
		UPDATE profiles
		SET image_url = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def update_profile_live(id)
	DB.execute(<<~SQL, [now, id]).first['id']
		UPDATE profiles
		SET is_live = 1, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def show_public_profile?(is_live, profile_id)
	if is_live == 1
		true
	else
		session[:profile_id] && session[:profile_id] == profile_id
	end
end

def validate_profile(image_url, colour, bg_colour)
	combine_validators(	
		image_url ? valid_image?(image_url) : true,
		colour ? valid_colour?(colour) : true,
		bg_colour ? valid_colour?(bg_colour) : true
	)
end

def find_integration(id)
	DB.execute(<<~SQL, [id]).first
		SELECT id, profile_id, mailchimp_subscribe_url, created_at, updated_at
		FROM integrations
		WHERE id = ?
	SQL
end

def find_public_integration(username)
	DB.execute(<<~SQL, [username]).first
		SELECT i.mailchimp_subscribe_url
		FROM integrations i
		INNER JOIN profiles p ON i.profile_id = p.id
		WHERE p.username = ?
	SQL
end

def create_integration(profile_id)
	DB.execute(<<~SQL, [profile_id, now, now]).first['id']
		INSERT INTO integrations (profile_id, created_at, updated_at)
		VALUES (?, ?, ?)
		RETURNING id
	SQL
end

def update_integration(id, subscribe_url)
	DB.execute(<<~SQL, [subscribe_url, now, id]).first['id']
		UPDATE integrations
		SET mailchimp_subscribe_url = ?, updated_at = ?
		WHERE id = ?
		RETURNING id
	SQL
end

def get_subscribe_url(api_key)
	region = api_key.split('-')[1]
	lists_url = URI("https://#{region}.api.mailchimp.com/3.0/lists")
	headers = { 'Authorization' => "Bearer #{api_key}" }

	response = Net::HTTP.get(lists_url, headers)
	url = JSON.parse(response)['lists'][0]['subscribe_url_long']
	parts = url.split('?')

	"#{parts[0]}/post?#{parts[1]}"
end

def find_pw_reset_request(uuid)
	DB.execute(<<~SQL, [uuid]).first
		SELECT id, uuid, user_id, created_at, updated_at
		FROM pw_reset_requests
		WHERE uuid = ?
	SQL
end

def create_pw_reset_request(user_id, email)
	uuid = SecureRandom.uuid

	DB.execute(<<~SQL, [uuid, user_id, now, now])
		INSERT INTO pw_reset_requests (uuid, user_id, created_at, updated_at)
		VALUES (?, ?, ?, ?)
	SQL

	send_forgot_pw_email(uuid, email)
end

def expired_pw_reset_request?(uuid, hours)
	created_at = DB.execute(<<~SQL, [uuid]).first['created_at']
		SELECT created_at
		FROM pw_reset_requests
		WHERE uuid = ?
	SQL

	diff = DateTime.now.to_time.to_i - DateTime.parse(created_at).to_time.to_i
	diff > 3600 * hours
end

def send_forgot_pw_email(uuid, email)
	link = "https://#{ENV.fetch('HOSTNAME')}/forgot-password/#{uuid}"

	message = <<~EMAIL
		From: #{ENV.fetch('MAILER')}
		To: #{email}
		Subject: Teatree -- Forgot password

		Click this link to reset your password <#{link}>
	EMAIL

	Net::SMTP.start(
		ENV.fetch('SMTP_HOST'),
		ENV.fetch('SMTP_PORT'),
		helo: ENV.fetch('HOSTNAME'),
		user: ENV.fetch('SMTP_USER'),
		secret: ENV.fetch('SMTP_PASS')
	) do |smtp|
		smtp.send_message(message, ENV.fetch('MAILER'), email)
	end
end
