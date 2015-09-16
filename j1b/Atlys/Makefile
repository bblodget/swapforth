CPU = j1b
CROSSDIR = ..
BUILDDIR = ../build
SRCDIR = .
DEMOSDIR = demos
BITFILE = ise14.7/$(CPU)/top.bit
BMMFILE = $(CPU)_atlys_bd.bmm

all: nuc hello

### START nuc rules #####

nuc: $(BUILDDIR)/nuc.bit

$(BUILDDIR)/nuc.bit: $(BUILDDIR)/nuc.mem $(SRCDIR)/$(BMMFILE) $(BITFILE)
	data2mem -bm $(SRCDIR)/$(BMMFILE) -bt $(BITFILE) -bd $(BUILDDIR)/nuc.mem tag $(CPU) -o b $(SRCDIR)/nuc.bit

$(BUILDDIR)/nuc.mem: $(BUILDDIR)/nuc.hex $(BUILDDIR)/addr.txt
	cat $(BUILDDIR)/addr.txt $(BUILDDIR)/nuc.hex > $(BUILDDIR)/nuc.mem

$(BUILDDIR)/nuc.hex: $(CROSSDIR)/cross.fs $(CROSSDIR)/basewords.fs $(CROSSDIR)/nuc.fs
	cd $(CROSSDIR) && \
	gforth cross.fs basewords.fs nuc.fs # && \

### END nuc rules #####

### START hello rules #####

hello: $(BUILDDIR)/hello.bit

$(BUILDDIR)/hello.bit: $(BUILDDIR)/hello.mem $(SRCDIR)/$(BMMFILE) $(BITFILE)
	data2mem -bm $(SRCDIR)/$(BMMFILE) -bt $(BITFILE) -bd $(BUILDDIR)/hello.mem tag $(CPU) -o b $(SRCDIR)/hello.bit

$(BUILDDIR)/hello.mem: $(BUILDDIR)/hello.hex $(BUILDDIR)/addr.txt
	cat $(BUILDDIR)/addr.txt $(BUILDDIR)/hello.hex > $(BUILDDIR)/hello.mem

$(BUILDDIR)/hello.hex: $(CROSSDIR)/cross.fs $(CROSSDIR)/basewords.fs $(DEMOSDIR)/hello.fs
	cp $(DEMOSDIR)/hello.fs $(CROSSDIR)
	cd $(CROSSDIR) && \
	gforth cross.fs basewords.fs hello.fs && \
	rm hello.fs

### END hello rules #####

clean:
	rm -f $(BUILDDIR)/nuc.* 
	rm -f $(BUILDDIR)/hello.* 


