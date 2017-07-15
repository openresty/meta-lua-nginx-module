LEMPLATE_COMPILER?=lemplate
SUBSYSTEM?=http
TEMPLATE_RUNNER=utils/run_template.lua

TEMPLATE_SOURCES=$(wildcard src/*.tt2)
TEMPLATE_TARGETS=$(subst _meta_,_$(SUBSYSTEM)_, $(patsubst src/%.tt2, build/src/%, $(TEMPLATE_SOURCES)))

.PHONY: all
all: $(TEMPLATE_TARGETS)

build/src/%: build/templates.lua
	resty utils/run_template.lua $(SUBSYSTEM) $(@F)

build/templates.lua: $(TEMPLATE_SOURCES) build
	lemplate --compile $^ > $@

build:
	mkdir build
	mkdir build/src

.PHONY: clean
clean:
	rm -rf build
