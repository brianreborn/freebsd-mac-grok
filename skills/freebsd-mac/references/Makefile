# Light-ware License. Copyright (c) 2026 Brian Fundakowski Feldman. See LICENSE.
# Render pqac(7) to PDF. mandoc(1) from the FreeBSD base set.
#   make -C references -f Makefile
# or from the skill root:
#   mandoc -T pdf man/man7/pqac.7 > references/pqac.pdf

.POSIX:
SRC = ../man/man7/pqac.7
PDF = pqac.pdf

all: $(PDF)

$(PDF): $(SRC)
	mandoc -T lint $(SRC)
	mandoc -T pdf $(SRC) > $(PDF).tmp
	mv $(PDF).tmp $(PDF)

clean:
	rm -f $(PDF) $(PDF).tmp

.PHONY: all clean
