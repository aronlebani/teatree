# frozen_string_literal: true

get '/' do
	erb :index, :layout => false
end

get '/signup' do
	erb :signup
end

post '/signup' do
	errors = validate_signup(params[:email], params[:username], params[:password])

	unless errors.empty?
		flash[:errors] = errors
		redirect '/signup'
	end

	if email_exists?(params[:email])
		flash[:errors] = ['Email address is already registered.']
		redirect '/signup'
	end

	if username_exists?(params[:username])
		flash[:errors] = ['Username is already registered.']
		redirect '/signup'
	end

	user_id = create_user(params[:name], params[:email], params[:password])
	profile_id = create_profile(user_id, params[:username])
	create_integration(profile_id)

	session[:user_id] = user_id
	session[:profile_id] = profile_id

	redirect '/admin'
end

get '/login' do
	erb :login
end

post '/login' do
	user = find_auth_user_by_email(params[:email])

	unless user
		flash[:errors] = ['Incorrect username or password.']
		redirect '/login'
	end

	unless authenticated?(user['password'], params[:password])
		flash[:errors] = ['Incorrect username or password.']
		redirect '/login'
	end

	profile = find_profile_by_user_id(user['id'])

	session[:user_id] = user['id']
	session[:profile_id] = profile['id']

	redirect '/admin'
end

get '/logout' do
	session[:user_id] = nil
	session[:profile_id] = nil

	redirect '/login'
end

get '/forgot-password/new' do
	return 404 unless @forgot_pw_enabled

	erb :forgot_password_new
end

post '/forgot-password' do
	user = find_user_by_email(params[:email])
	errors = validate_user(params[:email])

	unless errors.empty?
		flash[:errors] = errors
		redirect '/forgot-password/new'
	end

	return 404 unless user

	create_pw_reset_request(user['id'], user['email'])

	"An email to reset your password has been sent to #{params[:email]}."
end

get '/forgot-password/:uuid' do
	if expired_pw_reset_request?(params[:uuid], 24)
		return [410, 'This link has expired']
	end

	erb :forgot_password_edit
end

post '/forgot-password/:uuid' do
	prr = find_pw_reset_request(params[:uuid])
	errors = validate_change_password(params[:new_password], params[:confirm_password])

	return 404 unless prr

	unless errors.empty?
		flash[:errors] = errors
		redirect "/forgot-password/#{params[:uuid]}"
	end

	update_user_password(prr['user_id'], params[:new_password])

	redirect '/login'
end

get '/admin' do
	@user = find_user(session[:user_id])
	@profile = find_profile(session[:profile_id])
	@links = find_all_links_by_profile_id(session[:profile_id])
	@integration = find_integration(session[:profile_id])

	return 404 unless @user && @profile

	erb :admin
end

get '/admin/link/new' do
	erb :link_new
end

post '/admin/link' do
	errors = validate_link(params[:href])

	unless errors.empty?
		flash[:errors] = errors
		redirect '/admin/link/new'
	end

	create_link(session[:profile_id], params[:title], params[:href])

	redirect '/admin'
end

get '/admin/link/:id/edit' do
	@link = find_link(params[:id])

	return 404 unless @link
	return 403 unless @link['profile_id'] == session[:profile_id]

	erb :link_edit
end

post '/admin/link/:id' do
	link = find_link(params[:id])
	errors = validate_link(params[:href])

	return 404 unless link
	return 403 unless link['profile_id'] == session[:profile_id]

	unless errors.empty?
		flash[:errors] = errors
		redirect "/admin/link/#{params[:id]}/edit"
	end

	update_link(link['id'], params[:title], params[:href])

	redirect '/admin'
end

post '/admin/link/:id/delete' do
	link = find_link(params[:id])

	return 404 unless link
	return 403 unless link['profile_id'] == session[:profile_id]

	delete_link(link['id'])

	redirect '/admin'
end

get '/admin/profile/:id/edit' do
	@profile = find_profile(params[:id])

	return 404 unless @profile
	return 403 unless @profile['id'] == session[:profile_id]

	erb :profile_edit
end

post '/admin/profile/:id' do
	profile = find_profile(params[:id])
	errors = validate_profile(params.dig('image', :filename), params[:colour], params[:bg_colour])

	return 404 unless profile
	return 403 unless profile['id'] == session[:profile_id]

	unless errors.empty?
		flash[:errors] = errors
		redirect "/admin/profile/#{params[:id]}/edit"
	end

	update_profile(params[:id], params[:title], params[:colour], params[:bg_colour], params[:image_alt], params[:css])

	if params[:image]
		update_profile_image(profile['id'], params[:image][:filename], params[:image][:tempfile])
	end

	redirect '/admin'
end

post '/admin/profile/:id/live' do
	profile = find_profile(params[:id])

	return 404 unless profile
	return 403 unless profile['id'] == session[:profile_id]

	update_profile_live(profile['id'])

	redirect '/admin'
end

get '/admin/user/:id/edit' do
	@user = find_user(params[:id])

	return 404 unless @user
	return 403 unless @user['id'] == session[:user_id]

	erb :user_edit
end

post '/admin/user/:id' do
	user = find_user(params[:id])
	errors = validate_user(params[:email])

	return 404 unless user
	return 403 unless user['id'] == session[:user_id]

	unless errors.empty?
		flash[:errors] = errors
		redirect "/admin/user/#{params[:id]}/edit"
	end

	if existing_email_not_mine? params[:email], user['id']
		flash[:errors] = ["The email #{params[:email]} is already in use."]
		redirect "/admin/user/#{params[:id]}/edit"
	end

	update_user(user['id'], params[:name], params[:email])

	redirect '/admin'
end

get '/admin/change-password' do
	erb :change_password_edit
end

post '/admin/change-password' do
	user = find_auth_user(session[:user_id])
	errors = validate_change_password(params[:new_password], params[:confirm_password])

	return 404 unless user

	unless errors.empty?
		flash[:errors] = errors
		redirect '/admin/change-password'
	end

	unless authenticated?(user['password'], params[:old_password])
		flash[:errors] = ['Incorrect password']
		redirect '/admin/change-password'
	end

	update_user_password(user['id'], params[:new_password])

	session[:user_id] = nil
	session[:profile_id] = nil

	redirect '/login'
end

get '/admin/integration/:id/mailchimp/edit' do
	@integration = find_integration(params[:id])

	return 404 unless @integration
	return 403 unless @integration['profile_id'] == session[:profile_id]

	erb :integration_mailchimp_edit
end

post '/admin/integration/:id/mailchimp' do
	integration = find_integration(params[:id])

	return 404 unless integration
	return 403 unless integration['profile_id'] == session[:profile_id]

	begin
		subscribe_url = get_subscribe_url(params[:mailchimp_api_key])
		update_integration(integration['id'], subscribe_url)
	rescue
		flash[:errors] = ['Could not parse API key.']
		redirect "/admin/integration/#{params[:id]}/mailchimp/edit"
	end

	redirect '/admin'
end

get '/userdata/:file' do
	# Let nginx serve static files in production
	pass unless ENV.fetch('ENV') == 'development'

	# Can't have two public directories, so this is the workaround.
	send_file(File.join(__dir__, ENV.fetch('USERDATA_DIR'), params[:file]))
end

get '/:username' do
	@profile = find_public_profile(params[:username])
	@integration = find_public_integration(params[:username])
	@links = find_all_public_links(params[:username])

	return 404 unless @profile

	unless show_public_profile?(@profile['is_live'], @profile['id'])
		return 404
	end

	erb :public_profile, layout: false
end

before do
	@hostname = ENV.fetch('HOSTNAME')
	@forgot_pw_enabled =
		ENV.fetch('SMTP_HOST') &&
		ENV.fetch('SMTP_PORT') &&
		ENV.fetch('SMTP_PASS') &&
		ENV.fetch('SMTP_USER') &&
		ENV.fetch('MAILER')
end

before /\/admin.*/ do
	redirect '/login' unless session[:user_id] && session[:profile_id]
end

error 403 do
	'Unauthorized.'
end

error 404 do
	'Not found.'
end

error do
	[500, 'Oops, something went wrong...']
end
