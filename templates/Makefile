# Copy to the chip repo root. Bump TOOLCHAIN_REF on purpose, never track main.
TOOLCHAIN_REF ?= v0.3
TC := .toolchain
ifeq (,$(wildcard $(TC)/chip.mk))
$(shell rm -rf $(TC); gh repo clone TuriChips/toolchain $(TC) -- -q --depth 1 --branch $(TOOLCHAIN_REF))
endif
include $(TC)/chip.mk
