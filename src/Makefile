all: codegen

codegen: lex.yy.c y.tab.c
	gcc -o $@ $^ -lfl

y.tab.c y.tab.h y.output &: parser.y
	byacc -d -v $^

lex.yy.c: scanner.l y.tab.h
	flex $<

.PHONY: clean
clean: 
	rm -rf lex.yy.c y.tab.c y.tab.h y.output codegen.S


