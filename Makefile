include .env

LISP ?= sbcl
EXE = teatree

.PHONY: debug build clean deploy

debug:
	$(LISP) --load teatree.asd \
		--eval '(ql:quickload :teatree)' \
		--eval '(teatree:main)'

build:
	$(LISP) --load teatree.asd \
		--eval '(ql:quickload :teatree)' \
		--eval '(asdf:make :teatree)' \
		--eval '(quit)'

clean:
	rm $(EXE)

deploy:
	chmod -R +x $(EXE)
	rsync -rvsp --delete --progress public $(EXE) ${SERVER}:${DEST}
	ssh ${SERVER} 'systemctl restart $(EXE).service'
