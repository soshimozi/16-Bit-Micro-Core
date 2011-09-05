PROGRAM = asm 
SOURCES = main.c parser.c scanner.c
OBJECTS = main.o parser.o scanner.o
GENERATED = parser.h parser.c scanner.h scanner.c

LEX = flex
YACC = bison
CC = g++

CFLAGS = -g -D_REENTRANT
LDFLAGS =
LIBS = 

MF = makefile

.SUFFIXES: .o .h .cc .l .y

main: $(PROGRAM)
		  @ls -l $(PROGRAM)

test: $(PROGRAM)
		  @ls -l $(PROGRAM)
			@./$(PROGRAM) test.asm

version:
	  	$(CC) --version
.cc.o:
		@echo compiling $<
		@$(CC) $(CFLAGS) -c -o $*.o $<
.c.o:
		@echo compiling $<
		@$(CC) $(CFLAGS) -c -o $*.o $<
.l.c:
		@echo building scanner $<
		@$(LEX) -o$*.c $<

.y.c:
		@echo building parser $<
		@$(YACC) --defines=$*.h -o$*.c $<

install: $(PROGRAM)
		@echo Installing...
		@cp $(PROGRAM) $(HOME)/dev/Tools/$(PROGRAM)

$(PROGRAM): $(OBJECTS)
		@echo linking...
		@$(CC) -o $(PROGRAM) $(CFLAGS) $(LDFLAGS) $(OBJECTS) $(LIBS)
clean:
		@echo "Deleting temporary files..."
		@rm -f *~ "#*" $(OBJECTS) $(PROGRAM) $(GENERATED)
		
rebuild:
		@echo "Deleting intermediate files..."
		@rm -f *~ $(OBJECTS) $(PROGRAM) $(GENERATED)
		@make
dep depend:
		@echo 'Updating dependencies for: '
		@echo '    ' $(SOURCES)
		@{  \
		< $(MF) sed -n '1,/^###.*SUDDEN DEATH/p'; \
				echo '#' ; \
				echo '# dependencies generated on: ' `date` ; \
				echo '#' ; \
				for i in $(SOURCES); do \
					$(CC) -MM $(CFLAGS) $(DEFINES) $$i; \
					echo; \
				done; \
			} > $(MF).new
			@mv $(MF) $(MF).last
			@mv $(MF).new $(MF)
			
parser.c : parser.h
scanner.c : scanner.l
parser.h : parser.y scanner.l
scanner.o : scanner.c
parser.o : parser.c
parser.c : scanner.c

############## EVERYTHING BELOW THIS LINE IS SUBJECT TO SUDDEN DEATH...
#
# dependencies generated on:  Thu Aug 11 22:01:36 PDT 2011
#
main.o: main.c assembler.h

parser.o: parser.c assembler.h sys.h

scanner.o: scanner.c parser.h assembler.h

