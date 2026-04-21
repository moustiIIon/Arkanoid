ROM     = unbrick.gb
SRC     = main.asm
OBJ     = main.o
ASM     = rgbasm
LINK    = rgblink
FIX     = rgbfix
ASMFLAGS  = -I .
LINKFLAGS =
FIXFLAGS  = -v -p 0xFF

all: $(ROM)

$(OBJ): $(SRC) hardware.inc
	$(ASM) $(ASMFLAGS) -o $(OBJ) $(SRC)

$(ROM): $(OBJ)
	$(LINK) $(LINKFLAGS) -o $(ROM) $(OBJ)
	$(FIX) $(FIXFLAGS) $(ROM)

clean:
	rm -f $(OBJ) $(ROM)

re: clean all

.PHONY: all clean re