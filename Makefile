include .env

RUBY ?= ruby

.PHONY: install
install:
	bundle install

.PHONY: debug
debug:
	$(RUBY) main.rb -e development -p $(PORT)

.PHONY: start
start:
	$(RUBY) main.rb -e production -p $(PORT)

.PHONY: deploy
deploy:
	rsync -rvsp --delete --progress \
		Makefile Gemfile Gemfile.lock *.rb views public scripts \
		$(APP_HOST):$(APP_DEST)
	ssh $(APP_HOST) 'systemctl restart teatree.service'
