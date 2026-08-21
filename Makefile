# Build Coq sources according to `_CoqProject`.

COQ_MAKEFILE := coq_makefile
REDIR := $(MAKE) -f Makefile.coq
JS_TO_COQ := theories/jessie/tools/js_to_coq_source.py
JS_SOURCES := theories/jessie/sources/makeCounter.js theories/jessie/sources/makeCounterExo.js theories/jessie/sources/makeCounterZone.js theories/jessie/sources/escrow2013.js
GENERATED_JS_V := theories/jessie/makeCounter_js.v theories/jessie/makeCounterExo_js.v theories/jessie/makeCounterZone_js.v theories/jessie/escrow2013_js.v
MENHIR_VY := theories/jessie/json_parser.vy theories/jessie/jesc_parser.vy
GENERATED_MENHIR_V := theories/jessie/json_parser.v theories/jessie/jesc_parser.v
MENHIR_FLAGS := --coq --coq-no-version-check

all: $(GENERATED_JS_V) $(GENERATED_MENHIR_V) Makefile.coq
	+@$(REDIR) $@
.PHONY: all

clean:
	@if [ -f Makefile.coq ]; then $(REDIR) $@; fi
	@echo CLEAN $(GENERATED_JS_V)
	@rm -f $(GENERATED_JS_V)
	@echo CLEAN $(GENERATED_MENHIR_V)
	@rm -f $(GENERATED_MENHIR_V)
.PHONY: clean

cleanall:
	@if [ -f Makefile.coq ]; then $(REDIR) cleanall; fi
	@echo CLEAN $(GENERATED_JS_V)
	@rm -f $(GENERATED_JS_V)
	@echo CLEAN $(GENERATED_MENHIR_V)
	@rm -f $(GENERATED_MENHIR_V)
	@echo CLEAN Makefile.coq Makefile.coq.conf
	@rm -f Makefile.coq Makefile.coq.conf
.PHONY: cleanall

$(GENERATED_JS_V): theories/jessie/%_js.v: theories/jessie/sources/%.js $(JS_TO_COQ)
	@echo GEN $@
	@python3 $(JS_TO_COQ) $< $@

$(GENERATED_MENHIR_V): theories/jessie/%_parser.v: theories/jessie/%_parser.vy
	@echo MENHIR $@
	@menhir $(MENHIR_FLAGS) -b $(basename $@) $<

# Enable $(REDIR)
Makefile.coq Makefile.coq.conf: _CoqProject Makefile $(GENERATED_JS_V) $(GENERATED_MENHIR_V)
	+@echo COQ_MAKEFILE
	+@$(COQ_MAKEFILE) -f _CoqProject -o Makefile.coq

# $(REDIR)
%: Makefile.coq
	+@$(REDIR) $@

# Don't $(REDIR)
Makefile _CoqProject $(JS_SOURCES) $(JS_TO_COQ) $(MENHIR_VY): ;
