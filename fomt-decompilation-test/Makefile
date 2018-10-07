.PHONY: compare clean
.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
    $(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

AS        := $(DEVKITARM)/bin/arm-none-eabi-as
LD        := $(DEVKITARM)/bin/arm-none-eabi-ld
OBJCOPY   := $(DEVKITARM)/bin/arm-none-eabi-objcopy
CPP       := $(DEVKITARM)/bin/arm-none-eabi-cpp
CC1PLUS   := agbcc/agbcxx

ROM       := roms/fomt.gba
ELF       := $(ROM:.gba=.elf)
MAP       := $(ROM:.gba=.map)
LDSCRIPT  := ld.txt
# CXXFILES  := $(wildcard *.cpp)

CPPFLAGS  := -iquote . -nostdinc -undef
CC1FLAGS  := -fembedded-cxx -mthumb-interwork -Wimplicit -Wparentheses -Werror -O2 -fhex-asm
ASFLAGS   := -mcpu=arm7tdmi -mthumb-interwork -I .


OBJECTS   := data_0.o data_DBC8.o data_E963C.o Tool.o

compare: $(ROM)
	sha1sum -c checksum.sha1

clean:
	@$(RM) $(OBJECTS) $(ELF) $(ROM) $(MAP)

$(ELF): $(OBJECTS) $(LDSCRIPT)
	$(LD) -T $(LDSCRIPT) -Map $(MAP) $(OBJECTS) -o $@

%.gba: %.elf
	$(OBJCOPY) -O binary --pad-to 0x8800000 $< $@

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

%.s: %.cpp
	$(CPP) $(CPPFLAGS) $< | $(CC1PLUS) $(CC1FLAGS) -o $@
	@echo '.align 2, 0' >> $@
