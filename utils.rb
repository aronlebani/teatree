# frozen_string_literal: true

def now()
  DateTime.now.to_s
end

def invalid_username?(username)
  unless username.match? /^[a-zA-Z_]+[a-zA-Z0-9_-]+/
    'Username should be a combination of letters, numbers, and underscores, where the first character is a letter or underscore.'
  end
end

def invalid_password?(password)
  unless password.length >= 8
    'Password should be minimum 8 characters.'
  end
end

def invalid_colour?(colour)
  unless colour.match? /^\#{1}[a-fA-F0-9]{6}/
    'Invalid colour.'
  end
end

def invalid_image?(image)
  unless image.match? /.+(.jpe?g|.png)$/
    'Only jpg and png images are supported.'
  end
end

def invalid_email?(email)
  unless email.match? /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/
    'Invalid email.'
  end
end

def invalid_url?(url)
  unless url.match? /((([A-Za-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[A-Za-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[A-Za-z0-9\.\-]+)((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\-\+=&;%@\.\w_]*)#?(?:[\.\!\/\\\w]*))?)/
    'Invalid URL.'
  end
end

def make_userdata_path(filename, area, id)
  ext = File.extname filename
  timestamp = DateTime.now.to_time.to_i

  File.join ENV['USERDATA_DIR'], "#{area}.#{id}.#{timestamp}#{ext}"
end
