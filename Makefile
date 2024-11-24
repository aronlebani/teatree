include .env

RUBY ?= ruby
FILES = Makefile Gemfile Gemfile.lock config.ru *.rb views public scripts

install:
	bundle install

debug:
	$(RUBY) main.rb -e development -p $(PORT)

start:
	$(RUBY) main.rb -e production -p $(PORT)

deploy:
	rsync -rvsp --delete $(FILES) $(APP_HOST):$(APP_DEST)

.PHONY: install debug start deploy
