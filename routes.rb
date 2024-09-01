# frozen_string_literal: true

# --- Index ---

get '/' do
  erb :index, layout: false
end

# --- Signup ---

get '/signup' do
  erb :signup
end

post '/signup' do
  errors = validate_signup params['email'], params['username'], params['password']

  if !errors.empty?
    flash['errors'] = errors
    redirect '/signup'
  elsif email_exists? params['email']
    flash['errors'] = ['Email address is already registered.']
    redirect '/signup'
  elsif username_exists? params['username']
    flash['errors'] = ['Username is already registered.']
    redirect '/signup'
  end

  user_id = create_user params['name'], params['email'], params['password']
  profile_id = create_profile user_id, params['username']
  create_integration profile_id

  session['user_id'] = user_id
  session['profile_id'] = profile_id

  redirect '/admin'
end

# --- Login ---

get '/login' do
  erb :login
end

post '/login' do
  user = find_auth_user_by_email params['email']

  if !user
    flash['errors'] = ['Incorrect username or password.']
    redirect '/login'
  elsif !authenticated? user['password'], params['password']
    flash['errors'] = ['Incorrect username or password.']
    redirect '/login'
  end

  profile = find_profile_by_user_id user['id']

  session['user_id'] = user['id']
  session['profile_id'] = profile['id']

  redirect '/admin'
end

# --- Logout ---

get '/logout' do
  session['user_id'] = nil
  session['profile_id'] = nil

  redirect '/login'
end

# --- Forgot password ---

get '/forgot-password/new' do
  if !@forgot_pw_enabled
    return 404
  end

  erb :forgot_password_new
end

post '/forgot-password' do
  user = find_user_by_email params['email']

  if !user
    return 404
  end

  create_pw_reset_request user['id'], user['email']

  "An email to reset your password has been sent to #{params['email']}."
end

get '/forgot-password/:uuid' do
  if expired_pw_reset_request? params['uuid'], 24
    return [410, 'This link has expired']
  end

  erb :forgot_password_edit
end

post '/forgot-password/:uuid' do
  prr = find_pw_reset_request params['uuid']

  errors = validate_change_password params['new_password'], params['confirm_password']

  if !prr
    return 404
  elsif !errors.empty?
    flash['errors'] = errors
    redirect "/forgot-password/#{params['uuid']}"
  end
  
  update_user_password prr['user_id'], params['new_password']

  redirect '/login'
end

# --- Public profile ---

get '/u/:username' do
  @profile = find_public_profile params['username']
  @integration = find_public_integration params['username']

  if !@profile
    return 404
  end

  @links = find_all_public_links params['username']

  if !show_public_profile? @profile['is_live'], @profile['id'], session['profile_id']
    return 404
  end

  erb :public_profile
end

# --- Admin ---

get '/admin' do
  @user = find_user session['user_id']
  @profile = find_profile session['profile_id']
  @links = find_all_links_by_profile_id session['profile_id']
  @integration = find_integration session['profile_id']

  if !@user || !@profile
    return 404
  end

  erb :admin
end

# --- Link ---

get '/link/new' do
  erb :link_new
end

post '/link' do
  errors = validate_link params['href']

  if !errors.empty?
    flash['errors'] = errors
    redirect '/link/new'
  end

  create_link session['profile_id'], params['title'], params['href']

  redirect '/admin'
end

get '/link/:id/edit' do
  @link = find_link params['id']

  if !@link
    return 404
  elsif @link['profile_id'] != session['profile_id']
    return 403
  end

  erb :link_edit
end

post '/link/:id' do
  link = find_link params['id']

  errors = validate_link params['href']

  if !link
    return 404
  elsif link['profile_id'] != session['profile_id']
    return 403
  elsif !errors.empty?
    flash['errors'] = errors
    redirect "/link/#{params['id']}/edit"
  end

  update_link link['id'], params['title'], params['href']

  redirect '/admin'
end

post '/link/:id/delete' do
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

get '/profile/:id/edit' do
  @profile = find_profile params['id']

  if !@profile
    return 404
  elsif @profile['id'] != session['profile_id']
    return 403
  end

  erb :profile_edit
end

post '/profile/:id' do
  profile = find_profile params['id']

  errors = validate_profile params['image'][:filename], params['colour'], params['bg_colour']

  if !profile
    return 404
  elsif profile['id'] != session['profile_id']
    return 403
  elsif !errors.empty?
    flash['errors'] = errors
    redirect "/profile/#{params['id']}/edit"
  end

  update_profile params['id'], params['title'], params['colour'], params['bg_colour'], params['image_alt'], params['css']

  if params['image']
    update_profile_image profile['id'], params['image'][:filename], params['image'][:tempfile]
  end

  redirect '/admin'
end

post '/profile/:id/live' do
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

get '/user/:id/edit' do
  @user = find_user params['id']

  if !@user
    return 404
  elsif @user['id'] != session['user_id']
    return 403
  end

  erb :user_edit
end

post '/user/:id' do
  user = find_user params['id']

  errors = validate_user params['email']

  if !user
    return 404
  elsif user['id'] != session['user_id']
    return 403
  elsif !errors.empty?
    flash['errors'] = errors
    redirect "/user/#{params['id']}/edit"
  elsif existing_email_not_mine? params['email'], user['id']
    flash['errors'] = ["The email #{params['email']} is already in use."]
    redirect "/user/#{params['id']}/edit"
  end

  update_user user['id'], params['name'], params['email']

  redirect '/admin'
end

# --- Change password ---

get '/change-password' do
  erb :change_password_edit
end

post '/change-password' do
  user = find_auth_user session['user_id']

  errors = validate_change_password params['new_password'], params['confirm_password']

  if !user
    return 404
  elsif !errors.empty?
    flash['errors'] = errors
    redirect '/change-password'
  elsif !authenticated? user['password'], params['old_password']
    flash['errors'] = ['Incorrect password']
    redirect '/change-password'
  end

  update_user_password user['id'], params['new_password']

  session['user_id'] = nil
  session['profile_id'] = nil

  redirect '/login'
end

# --- Integration ---

# --- Mailchimp ---

get '/integration/:id/mailchimp/edit' do
  @integration = find_integration params['id']

  if !@integration
    return 404
  elsif @integration['profile_id'] != session['profile_id']
    return 403
  end

  erb :integration_mailchimp_edit
end

post '/integration/:id/mailchimp' do
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
    flash['errors'] = ['Could not parse API key.']
    redirect "/ingetration/#{params['id']}/mailchimp/edit"
  end

  redirect '/admin'
end

# --- Userdata ---

get '/userdata/:file' do
  # Can't have two public directories, so this is the workaround.
  send_file File.join __dir__, ENV['USERDATA_DIR'], params['file']
end

# --- Hooks ---

before do
  @hostname = ENV['HOSTNAME']

  @forgot_pw_enabled = ENV['SMTP_HOST'] &&
    ENV['SMTP_PORT'] &&
    ENV['SMTP_PASS'] &&
    ENV['SMTP_USER'] &&
    ENV['MAILER']
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

error 403 do
  "Unauthorized."
end

error 404 do
  "Not found."
end

error do
  [500, "Oops, something went wrong..."]
end
