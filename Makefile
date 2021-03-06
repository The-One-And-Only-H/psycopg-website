.PHONY: build serve setup docs publish

PYTHON=$(CURDIR)/env/bin/python
LEKTOR=$(CURDIR)/env/bin/lektor
DOC_BRANCH=master

TRACKING_ID = $(shell jq --raw-output '.tracking_id' databags/analytics.json)

build: docs
	test "$$TRAVIS" = "true" || test -d build/.git \
		|| git clone git@github.com:psycopg/psycopg.github.io.git build
	echo 'y' | $(LEKTOR) build -O build

serve:
	$(LEKTOR) serve

setup:
	test -x $(PYTHON) || virtualenv -p python3 env
	test -x $(LEKTOR) || env/bin/pip install -r requirements.txt

publish:
	git -C build add -A
	git -C build commit -m "updated on $$(date -Iseconds)"
	git -C build push

docs: psycopg2/doc/env psycopg2/doc/src/_templates/layout.html
	$(MAKE) PYTHON=$(PYTHON) -C psycopg2/doc html

psycopg2/doc/env: psycopg2/README.rst
	$(MAKE) PYTHON=$(PYTHON) -C psycopg2/doc env

psycopg2/README.rst:
	test -d psycopg2/.git \
		|| git clone -b $(DOC_BRANCH) https://github.com/psycopg/psycopg2.git
	git -C psycopg2 checkout $(DOC_BRANCH)
	git -C psycopg2 pull

psycopg2/doc/src/_templates/layout.html: templates/docs-layout.html databags/analytics.json
	mkdir -p $(dir $@)
	TRACKING_ID=${TRACKING_ID} envsubst < $< > $@
