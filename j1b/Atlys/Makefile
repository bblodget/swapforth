CROSSDIR = ..
BUILDDIR = ../build
SRCDIR = .
BITFILE = ise14.7/j1b/top.bit
BMMFILE = j1b_atlys_bd.bmm

all: nuc

### START nuc rules #####

nuc: $(BUILDDIR)/nuc.bit

$(BUILDDIR)/nuc.bit: $(BUILDDIR)/nuc.mem $(SRCDIR)/$(BMMFILE) $(BITFILE)
	data2mem -bm $(SRCDIR)/$(BMMFILE) -bt $(BITFILE) -bd $(BUILDDIR)/nuc.mem tag j1 -o b $(SRCDIR)/nuc.bit

$(BUILDDIR)/nuc.mem: $(BUILDDIR)/nuc.hex $(BUILDDIR)/addr.txt
	cat $(BUILDDIR)/addr.txt $(BUILDDIR)/nuc.hex > $(BUILDDIR)/nuc.mem

#$(BUILDDIR)/nuc.hex: $(CROSSDIR)/cross.fs $(CROSSDIR)/basewords.fs $(CROSSDIR)/nuc.fs
#	# cp nuc.fs $(CROSSDIR)
#	cd $(CROSSDIR) && \
#	gforth cross.fs basewords.fs nuc.fs # && \
#	# mv build/nuc.* ../../j1a/build && \
#	# rm nuc.fs

### END nuc rules #####

clean:
	rm -f $(BUILDIR)/nuc.* 


