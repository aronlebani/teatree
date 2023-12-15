LISP ?= sbcl
HOST =
PATH =
EXE = app

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
	rsync -rvsp --delete --progress public $(EXE) $(HOST):$(PATH)
	ssh $(HOST) 'systemctl restart $(EXE).service'
