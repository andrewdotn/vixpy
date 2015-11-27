RUBBER_INFO = rubber-info
RUBBER = rubber -m graphics -m xelatex --warn=refs --warn=misc
.SECONDARY:
SHELL = /bin/bash -eu

-include Makefile.local

all: presentation-skim.pdf

skim: presentation-skim.pdf
	open -a /Applications/Skim.app $<

.PHONY: .FORCE

labels.aux: presentation-skim.pdf
	grep '^\\newlabel' presentation.aux > $@ ||:

%.pdf: %.tex .FORCE
	${RUBBER} $<
	if grep -q 'fourupslides Warning: $*-skim.pdf not found' $*.log; then \
	    cat $@ > $*-skim.pdf; \
	    ${RUBBER} --force $<; \
	fi
	$(EXTRA_CMDS)

%-skim.pdf: %.pdf
	cat $< > $@

clean::
	rm -f *.aux *.log *.snm *.toc *.nav *.out *.toc *.vrb \
	    {annotated-,}presentation*.pdf \
	    transcript.tex transcript*.pdf

realclean:: clean
	rm -f {annotated-,}presentation-skim.pdf
