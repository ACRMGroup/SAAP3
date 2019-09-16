HTML = index.html ajax.js predictAjax.js
INCLUDES = $(WWW)/header.tt $(WWW)/footer.tt $(WWW)/main_menu.tt $(WWW)/mutations/mutations_menu.tt

all: $(HTML)

%.tt : %.tpl
	./tpl2tt.pl $< > $@

index.html : index.tt $(INCLUDES)
	@echo $(WWW)
	tpage --define WWW=$(WWW) $< > $@

ajax.js : ajax.tpl
	./tpl2tt.pl $< > $@

predictAjax.js : predictAjax.tpl
	./tpl2tt.pl $< > $@

clean:
	\rm $(HTML)
