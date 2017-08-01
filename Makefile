LEMPLATE_COMPILER?=lemplate
SUBSYSTEM?=http
TEMPLATE_RUNNER=utils/run_template.lua

TEMPLATE_SOURCES=$(wildcard src/subsystem/*.tt2)
TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYSTEM)_, $(patsubst src/subsystem/%.tt2, build/src/%, $(TEMPLATE_SOURCES)))
API_TEMPLATE_SOURCES=$(wildcard src/subsystem/api/*.tt2)
API_TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYSTEM)_, $(patsubst src/subsystem/%.tt2, build/src/%, $(API_TEMPLATE_SOURCES)))

.PHONY: all
all: $(TEMPLATE_TARGETS) $(API_TEMPLATE_TARGETS) $(SUBSYSTEM_TARGETS)
	cp src/$(SUBSYSTEM)/* build/src

build/src/%: build/templates.lua
	resty utils/run_template.lua $(SUBSYSTEM) $(@F)

build/src/api/%: build/templates.lua
	resty utils/run_template.lua $(SUBSYSTEM) $(@F)

build/templates.lua: $(TEMPLATE_SOURCES) $(API_TEMPLATE_SOURCES) build
	lemplate --compile $^ > $@

build:
	mkdir build
	mkdir build/src
	mkdir build/src/api

.PHONY: clean
clean:
	rm -rf build
