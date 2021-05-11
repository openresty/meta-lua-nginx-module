SUBSYS?=http
DESTDIR?=out/src

TEMPLATE_SOURCES=$(wildcard src/subsys/*.tt2)
TEMPLATE_TARGETS=$(subst _subsys_,_$(SUBSYS)_, $(patsubst src/subsys/%.tt2, $(DESTDIR)/%, $(TEMPLATE_SOURCES)))
API_TEMPLATE_SOURCES=$(wildcard src/subsys/api/*.tt2)
API_TEMPLATE_TARGETS=$(subst _subsys_,_$(SUBSYS)_, $(patsubst src/subsys/%.tt2, $(DESTDIR)/%, $(API_TEMPLATE_SOURCES)))
MINI_TT2=util/mini-tt2.pl

.PHONY: all clean

all: $(DESTDIR)/api $(TEMPLATE_TARGETS) $(API_TEMPLATE_TARGETS)
	find src/$(SUBSYS) -type f -name '*.tt2' -exec $(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) '{}' ';'
	$(shell cp src/$(SUBSYS)/*.{h,c} $(DESTDIR))

$(DESTDIR)/api/ngx_http_%: src/subsys/api/ngx_subsys_%.tt2
	$(MINI_TT2) -d $(DESTDIR)/api -s http $<

$(DESTDIR)/ngx_http_%: src/subsys/ngx_subsys_%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/api/ngx_stream_%: src/subsys/api/ngx_subsys_%.tt2
	$(MINI_TT2) -d $(DESTDIR)/api -s stream $<

$(DESTDIR)/ngx_stream_%: src/subsys/ngx_subsys_%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/%: src/subsys/%.tt2
	$(MINI_TT2) -d $(DESTDIR) -s $(SUBSYS) $<

$(DESTDIR)/api:
	mkdir -p $(DESTDIR)/api

clean:
	rm -rf out buildroot work t/servroot*
