HTML = index.html
INCLUDES = $(WWW)/header.tt $(WWW)/footer.tt $(WWW)/main_menu.tt $(WWW)/mutations/mutations_menu.tt

all: $(HTML)

clean:
	\rm $(HTML)
%.tt : %.tpl
	./tpl2tt.pl $< > $@

index.html : index.tt $(INCLUDES)
	@echo $(WWW)
	tpage --define WWW=$(WWW) $< > $@

