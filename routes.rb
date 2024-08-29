# frozen_string_literal: true

# --- Index ---

get '/' do
  erb :index, layout: false
end

# --- Signup ---

get '/signup' do # new
  hostname = ENV['HOSTNAME']

  erb :signup_new, locals: { hostname: hostname }
end

post '/signup' do # create
  if !valid_user? params['name'], params['email']
    return 400
  elsif !valid_username? params['username']
    return 400
  elsif email_exists? params['email']
    return [409, "The email address #{params['email']} is already registered."]
  elsif username_exists? params['username']
    return [409, "The username #{params['username']} is already registered."]
  end

  user_id = create_user params['name'], params['email'], params['password']
  profile_id = create_profile user_id, params['username']
  create_integration profile_id

  session['user_id'] = user_id
  session['profile_id'] = profile_id

  redirect '/admin'
end

# --- Login ---

get '/login' do # edit
  forgot_pw_enabled = ENV['SMTP_HOST'] && ENV['SMTP_PORT'] && ENV['SMTP_PASS'] \
    && ENV['SMTP_USER'] && ENV['MAILER']

  puts forgot_pw_enabled

  erb :login_edit, locals: { forgot_pw_enabled: forgot_pw_enabled }
end

post '/login' do # update
  user = find_auth_user_by_email params['email']

  if !user
    return [401, 'Incorrect username or password.']
  elsif !should_log_in? user['password'], params['password']
    return [401, 'Incorrect username or password.']
  end

  profile = find_profile_by_user_id user['id']
  session['user_id'] = user['id']
  session['profile_id'] = profile['id']

  redirect '/admin'
end

# --- Logout ---

get '/logout' do # destroy
  session['user_id'] = nil
  session['profile_id'] = nil

  redirect '/login'
end

# --- Forgot password ---

get '/forgot-password/new' do # new
  forgot_pw_enabled = ENV['SMTP_HOST'] && ENV['SMTP_PORT'] && ENV['SMTP_PASS'] \
    && ENV['SMTP_USER'] && ENV['MAILER']

  if !forgot_pw_enabled
    return 404
  end

  erb :forgot_password_new
end

post '/forgot-password' do # create
  user = find_user_by_email params['email']

  if !user
    return 404
  end

  create_pw_reset_request user['id'], user['email']

  "An email to reset your password has been sent to #{params['email']}."
end

get '/forgot-password/:uuid' do # edit
  if expired_pw_reset_request? params['uuid'], 24
    return [410, 'This link has expired']
  end

  erb :forgot_password_edit
end

post '/forgot-password/:uuid' do # update
  prr = find_pw_reset_request params['uuid']

  if !prr
    return 404
  elsif !valid_password? params['password']
    return 400
  end
  
  update_user_password prr['user_id'], params['password']

  redirect '/login'
end

# --- Change password ---

get '/change-password' do # edit
  erb :change_password_edit
end

post '/change-password' do # update
  user = find_auth_user session['user_id']

  if !user
    return 404
  elsif !valid_password? params['new_password']
    return 400
  end

  if !should_log_in? user['password'], params['old_password']
    return [401, 'Incorrect password']
  end

  update_user_password user['id'], params['new_password']
  session['user_id'] = nil
  session['profile_id'] = nil
  redirect '/login'
end

# --- Admin ---

get '/admin' do # show
  hostname = ENV['HOSTNAME']
  user = find_user session['user_id']
  profile = find_profile session['profile_id']
  links = find_all_links_by_profile_id session['profile_id']
  integration = find_integration session['profile_id']

  if !user || !profile
    return 404
  end

  erb :admin_show, locals: {
    user: user,
    profile: profile,
    links: links,
    integration: integration,
    hostname: hostname
  }
end

# --- Link ---

get '/link/new' do # new
  erb :link_new
end

post '/link' do # create
  if !valid_link? params['title'], params['href']
    return 400
  end

  create_link session['profile_id'], params['title'], params['href']
  redirect '/admin'
end

get '/link/:id/edit' do # edit
  link = find_link params['id']

  if !link
    return 404
  elsif link['profile_id'] != session['profile_id']
    return 403
  end

  erb :link_edit, locals: { link: link }
end

post '/link/:id' do # update
  link = find_link params['id']

  if !link
    return 404
  elsif link['profile_id'] != session['profile_id']
    return 403
  elsif !valid_link? params['title'], params['href']
    return 400
  end

  update_link link['id'], params['title'], params['href']

  redirect '/admin'
end

post '/link/:id/delete' do # destroy
  link = find_link params['id']

  if !link
    return 404
  elsif link['profile_id'] != session['profile_id']
    return 403
  end

  delete_link link['id']

  redirect '/admin'
end

# --- Profile ---

get '/profile/:id/edit' do # edit
  profile = find_profile params['id']

  if !profile
    return 404
  elsif profile['id'] != session['profile_id']
    return 403
  end

  erb :profile_edit, locals: { profile: profile }
end

post '/profile/:id' do # update
  profile = find_profile params['id']

  if !profile
    return 404
  elsif profile['id'] != session['profile_id']
    return 403
  elsif !valid_profile? params['colour'], params['bg_colour']
    return 400
  end

  update_profile params['id'], params['title'], params['colour'], params['bg_colour'], params['image_alt'], params['css']

  if params['image']
    update_profile_image profile['id'], params['image'][:filename], params['image'][:tempfile]
  end

  redirect '/admin'
end

post '/profile/:id/live' do # update
  profile = find_profile params['id']

  if !profile
    return 404
  elsif profile['id'] != session['profile_id']
    return 403
  end

  update_profile_live profile['id']

  redirect '/admin'
end

# --- User ---

get '/user/:id/edit' do # edit
  user = find_user params['id']

  if !user
    return 404
  elsif user['id'] != session['user_id']
    return 403
  end

  erb :user_edit, locals: { user: user }
end

post '/user/:id' do # update
  user = find_user params['id']

  if !user
    return 404
  elsif user['id'] != session['user_id']
    return 403
  elsif !valid_user? params['name'], params['email']
    return 400
  elsif existing_email_not_mine? params['email'], user['id']
    return [409, "The email #{params['email']} is already in use."]
  end

  update_user user['id'], params['name'], params['email']

  redirect '/admin'
end

# --- Integration ---

# --- Mailchimp ---

get '/integration/:id/mailchimp/edit' do # edit
  integration = find_integration params['id']

  if !integration
    return 404
  elsif integration['profile_id'] != session['profile_id']
    return 403
  end

  erb :integration_mailchimp_edit, locals: { integration: integration }
end

post '/integration/:id/mailchimp' do # update
  integration = find_integration params['id']

  if !integration
    return 404
  elsif integration['profile_id'] != session['profile_id']
    return 403
  end

  begin
    subscribe_url = get_subscribe_url params['mailchimp_api_key']
    update_integration integration['id'], subscribe_url
  rescue
    return [400, 'Could not parse API key.']
  end

  redirect '/admin'
end

# --- Public profile ---

get '/u/:username' do # show
  profile = find_public_profile params['username']
  integration = find_public_integration params['username']

  if !profile
    return 404
  end

  links = find_all_public_links params['username']

  if !show_public_profile? profile['is_live'], profile['id'], session['profile_id']
    return 404
  end

  erb :public_profile_show, locals: {
    profile: profile,
    links: links,
    integration: integration
  }, layout: false
end

# --- Userdata ---

get '/userdata/:file' do
  # Can't have two public directories, so this is the workaround.
  send_file File.join __dir__, ENV['USERDATA_DIR'], params['file']
end

# --- Authenticated ---

before /\/change-password|\/admin|\/profile\/.*|\/link\/.*|\/user\/.*/ do
  # This is error-prone. Would be better to reverse this logic, but it's
  # problematic for /:username routes.
  if !session['user_id'] || !session['profile_id']
    redirect '/login'
  end
end

# --- Error handlers ---

error 400 do
  "Invalid request."
end

error 403 do
  "Unauthorized."
end

error 404 do
  "Not found."
end

error do
  [500, "Oops, something went wrong..."]
end
