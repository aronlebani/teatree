# frozen_string_literal: true

def now()
  DateTime.now.to_s
end

def invalid_username?(username)
  return if username.match? /^[a-zA-Z_]+[a-zA-Z0-9_-]+/

  'Username should be a combination of letters, numbers, and underscores, where the first character is a letter or underscore.'
end

def invalid_password?(password)
  return if password.length >= 8

  'Password should be minimum 8 characters.'
end

def invalid_colour?(colour)
  return if colour.match? /^\#{1}[a-fA-F0-9]{6}/

  'Invalid colour.'
end

def invalid_image?(image)
  return if image.match? /.+(.jpe?g|.png)$/

  'Only jpg and png images are supported.'
end

def invalid_email?(email)
  return if email.match? /\A#{URI::MailTo::EMAIL_REGEXP}\z/

  'Invalid email.'
end

def invalid_url?(url)
  return if url.match? /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/

  'Invalid URL.'
end

def make_userdata_path(filename, area, id)
  ext = File.extname filename
  timestamp = DateTime.now.to_time.to_i

  File.join ENV['USERDATA_DIR'], "#{area}.#{id}.#{timestamp}#{ext}"
end
