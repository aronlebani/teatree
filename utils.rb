# frozen_string_literal: true

USERNAME_REGEX = /^[a-zA-Z_]+[a-zA-Z0-9_-]+/
COLOUR_REGEX = /^\#{1}[a-fA-F0-9]{6}/
IMAGE_REGEX = /.+(.jpe?g|.png)$/
EMAIL_REGEX = /\A#{URI::MailTo::EMAIL_REGEXP}\z/
URL_REGEX = /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/

def now = DateTime.now.to_s

def valid_username?(val)
	val.match?(USERNAME_REGEX) || 'Username should be a combination of letters, numbers, and underscores, where the first character is a letter or underscore.'
end

def valid_password?(val)
	val.length >= 8 || 'Password should be minimum 8 characters.'
end

def valid_colour?(val)
	val.match?(COLOUR_REGEX) || 'Invalid colour.'
end

def valid_image?(val)
	val.match?(IMAGE_REGEX) || 'Only jpg and png images are supported.'
end

def valid_email?(val)
	val.match?(EMAIL_REGEX) || 'Invalid email.'
end

def valid_url?(val)
	val.match?(URL_REGEX) || 'Invalid URL.'
end

def combine_validators(*validators)
	validators.filter { |v| v != true }
end

def make_userdata_path(filename, area, id)
	ext = File.extname(filename)
	timestamp = DateTime.now.to_time.to_i

	File.join(ENV.fetch('USERDATA_DIR'), "#{area}.#{id}.#{timestamp}#{ext}")
end
