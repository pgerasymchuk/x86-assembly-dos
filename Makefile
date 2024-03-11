# Builds DOS .EXE files with JWasm (MASM-compatible, runs on Linux/Windows/macOS).
# Output names follow the DOS 8.3 rule so they can be started from DOSBox.

ASM ?= jwasm
BUILD := build

PROGRAMS := REVERSE:array-reverse.asm \
            SIGNIO:signed-io.asm \
            FUNCXY:piecewise-function.asm \
            ARRSORT:array-stats-sort.asm \
            MATRIX:matrix-search.asm \
            SIGNIOM:macros/signed-io-macro.asm \
            FUNCXYM:macros/piecewise-function-macros.asm \
            MATRIXM:macros/matrix-search-macros.asm

name = $(word 1,$(subst :, ,$(1)))
src  = $(word 2,$(subst :, ,$(1)))

EXES := $(foreach p,$(PROGRAMS),$(BUILD)/$(call name,$(p)).EXE)

.PHONY: all dos-src clean

all: $(EXES)

define exe_rule
$(BUILD)/$(call name,$(1)).EXE: $(call src,$(1)) macros/macros.inc | $(BUILD)
	$$(ASM) -q -mz -Fo$$@ -Fl$(BUILD)/$(call name,$(1)).LST -Imacros $$<
endef
$(foreach p,$(PROGRAMS),$(eval $(call exe_rule,$(p))))

# Copies the sources under 8.3 names for assembling inside DOSBox with TASM or MASM.
dos-src: | $(BUILD)
	$(foreach p,$(PROGRAMS),cp $(call src,$(p)) $(BUILD)/$(call name,$(p)).ASM;)
	cp macros/macros.inc $(BUILD)/MACROS.INC

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)
