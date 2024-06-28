include .env

LISP ?= sbcl

.PHONY: debug start build clean deploy

debug:
	$(LISP) --load teatree.asd \
		--eval '(ql:quickload :teatree)' \
		--eval '(teatree:dbg)'

start:
	$(LISP) --load teatree.asd \
		--eval '(ql:quickload :teatree)' \
		--eval '(teatree:main)'

clean:
	rm *.fasl

deploy:
	rsync -rvsp --delete --progress \
		README.md LICENSE teatree.asd Makefile scripts src public ${SERVER}:${DEST}
	ssh ${SERVER} 'systemctl restart teatree.service'
