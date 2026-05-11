ROM     = cartridge.gb
SRCS    = main.asm
INCS    = $(shell find src -name '*.asm') hardware.inc
OBJ     = main.o
ASM     = rgbasm
LINK    = rgblink
FIX     = rgbfix
ASMFLAGS  = -I .
LINKFLAGS =
FIXFLAGS  = -v -p 0xFF -m MBC5+RAM+BATTERY -r 3

all: $(ROM)

$(OBJ): $(SRCS) $(INCS)
	$(ASM) $(ASMFLAGS) -o $(OBJ) $(SRCS)

$(ROM): $(OBJ)
	$(LINK) $(LINKFLAGS) -o $(ROM) $(OBJ)
	$(FIX) $(FIXFLAGS) $(ROM)

clean:
	rm -f $(OBJ) $(ROM) *.sav

re: clean all

.PHONY: all clean re