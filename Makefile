include .env

RUBY ?= ruby
FILES = Makefile Gemfile Gemfile.lock config.ru *.rb views public scripts

install:
	bundle install

debug:
	$(RUBY) -w main.rb -e development -p $(PORT)

start:
	$(RUBY) main.rb -e production -p $(PORT)

upload:
	rsync -rvsp $(FILES) $(APP_HOST):$(APP_DEST)
	ssh $(APP_HOST) 'chown -R www-data $(APP_DEST) & systemctl restart $(SERVICE)'

.PHONY: install debug start upload
