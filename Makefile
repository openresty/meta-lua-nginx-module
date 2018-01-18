LEMPLATE_COMPILER?=lemplate
SUBSYSTEM?=http
TEMPLATE_RUNNER=utils/run_template.lua

TEMPLATE_SOURCES=$(wildcard src/subsystem/*.tt2)
TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYSTEM)_, $(patsubst src/subsystem/%.tt2, build/src/%, $(TEMPLATE_SOURCES)))
API_TEMPLATE_SOURCES=$(wildcard src/subsystem/api/*.tt2)
API_TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYSTEM)_, $(patsubst src/subsystem/%.tt2, build/src/%, $(API_TEMPLATE_SOURCES)))
MINI_TT2=utils/mini-tt2.pl

.PHONY: all
all: build $(TEMPLATE_TARGETS) $(API_TEMPLATE_TARGETS) $(SUBSYSTEM_TARGETS)
	cp src/$(SUBSYSTEM)/* build/src

build/src/api/ngx_http_%: src/subsystem/api/ngx_subsystem_%.tt2
	$(MINI_TT2) -d build/src/api -s http $<

build/src/ngx_http_%: src/subsystem/ngx_subsystem_%.tt2
	$(MINI_TT2) -d build/src -s $(SUBSYSTEM) $<

build/src/api/ngx_stream_%: src/subsystem/api/ngx_subsystem_%.tt2
	$(MINI_TT2) -d build/src/api -s stream $<

build/src/ngx_stream_%: src/subsystem/ngx_subsystem_%.tt2
	$(MINI_TT2) -d build/src -s $(SUBSYSTEM) $<

build/src/%: src/subsystem/%.tt2
	$(MINI_TT2) -d build/src -s $(SUBSYSTEM) $<

build:
	mkdir -p build/src/api

.PHONY: clean
clean:
	rm -rf build
