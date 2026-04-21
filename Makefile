# ============================================================
#  CARTRIDGE - Makefile
#  Compilation avec RGBDS (rgbasm + rgblink + rgbfix)
# ============================================================

# Nom de la ROM finale
ROM     = unbrick.gb

# Sources
SRC     = main.asm

# Fichier objet généré
OBJ     = main.o

# Outils RGBDS
ASM     = rgbasm
LINK    = rgblink
FIX     = rgbfix

# Flags
ASMFLAGS  = -I .       # inclure le dossier courant pour les INCLUDE
LINKFLAGS =
FIXFLAGS  = -v -p 0xFF # -v = valide le header, -p = padding avec 0xFF (MBC5)

# ============================================================

all: $(ROM)

# Etape 1 : Assemblage (.asm -> .o)
$(OBJ): $(SRC) hardware.inc
	$(ASM) $(ASMFLAGS) -o $(OBJ) $(SRC)

# Etape 2 : Link (.o -> .gb)
# Etape 3 : Fix du header (.gb valide pour emulateur)
$(ROM): $(OBJ)
	$(LINK) $(LINKFLAGS) -o $(ROM) $(OBJ)
	$(FIX) $(FIXFLAGS) $(ROM)

# Nettoyage
clean:
	rm -f $(OBJ) $(ROM)

re: clean all

.PHONY: all clean re