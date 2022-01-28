COPT = -g -c -I$(HOME)/include
LOPT = -L$(HOME)/lib

OFILES = sprotFTdist.o http-client/http-client.o

sprotFTdist : $(OFILES)
	gcc $(LOPT) -o $@ $(OFILES) -lbiop -lgen -lm -lxml2

.c.o :
	gcc $(COPT) -o $@ $<

clean :
	\rm -f $(OFILES)
