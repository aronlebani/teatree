# frozen_string_literal: true

def now()
  DateTime.now.to_s
end

def valid_username?(username)
  username.match? /^[a-zA-Z_]+[a-zA-Z0-9_-]+/
end

def valid_password?(password)
  password.length >= 8
end

def valid_colour?(colour)
  colour.match? /^\#{1}[a-fA-F0-9]{6}/
end

def valid_image?(image)
  image.match? /.+(.jpe?g|.png)$/
end

def valid_email?(email)
  email.match? /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
end

def valid_url?(url)
  url.match? /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/
end

def make_userdata_path(filename, area, id)
  ext = File.extname filename
  timestamp = DateTime.now.to_time.to_i

  File.join ENV['USERDATA_DIR'], "#{area}.#{id}.#{timestamp}#{ext}"
end
