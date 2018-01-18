SUBSYS?=http
DESTDIR?=build/src

TEMPLATE_SOURCES=$(wildcard src/subsystem/*.tt2)
TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYS)_, $(patsubst src/subsystem/%.tt2, $(DESTDIR)/%, $(TEMPLATE_SOURCES)))
API_TEMPLATE_SOURCES=$(wildcard src/subsystem/api/*.tt2)
API_TEMPLATE_TARGETS=$(subst _subsystem_,_$(SUBSYS)_, $(patsubst src/subsystem/%.tt2, $(DESTDIR)/%, $(API_TEMPLATE_SOURCES)))
MINI_TT2=utils/mini-tt2.pl

.PHONY: all
all: $(DESTDIR)/api $(TEMPLATE_TARGETS) $(API_TEMPLATE_TARGETS) $(SUBSYS_TARGETS)
	cp src/$(SUBSYS)/* $(DESTDIR)

$(DESTDIR)/api/ngx_http_%: src/subsystem/api/ngx_subsystem_%.tt2
	$(MINI_TT2) -d $(DESTDIR)/api -s http $<

$(DESTDIR)/ngx_http_%: src/subsystem/ngx_subsystem_%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/api/ngx_stream_%: src/subsystem/api/ngx_subsystem_%.tt2
	$(MINI_TT2) -d $(DESTDIR)/api -s stream $<

$(DESTDIR)/ngx_stream_%: src/subsystem/ngx_subsystem_%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/%: src/subsystem/%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/api:
	mkdir -p $(DESTDIR)/api

.PHONY: clean
clean:
	rm -rf build
