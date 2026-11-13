# Copy to the chip repo root. Bump TOOLCHAIN_REF on purpose, never track main.
TOOLCHAIN_REF ?= v0.1
TC := .toolchain
$(TC):
	gh repo clone TuriChips/toolchain $(TC) -- -q --depth 1 --branch $(TOOLCHAIN_REF)
include $(TC)/chip.mk
