include .env

RUBY ?= ruby
SCRIPT = config.ru *.rb views
PUBLIC = public/

install:
	bundle install

debug:
	$(RUBY) -w main.rb -e development -p $(PORT)

upload:
	rsync -rvsp $(SCRIPT) $(APP_HOST):$(APP_DEST)/script
	rsync -rvsp $(PUBLIC) $(APP_HOST):$(APP_DEST)/public
	ssh $(APP_HOST) 'chown -R www-data $(APP_DEST) & systemctl restart $(SERVICE)'

.PHONY: install debug upload
