REPORTER = dot
SPECS = $(shell find spec -name "*_spec.coffee" -type f)
BUILD_OPTS = \
	--compile \
	--output lib \
	src


test: build
	@./node_modules/.bin/mocha $(SPECS)	\
		--reporter $(REPORTER) \
		--compilers coffee:coffee-script \
		--colors

build:
	@./node_modules/.bin/coffee $(BUILD_OPTS)

watch: 
	@./node_modules/.bin/coffee --watch $(BUILD_OPTS)
