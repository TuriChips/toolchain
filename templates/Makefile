# Copy to the chip repo root. Bump TOOLCHAIN_REF on purpose, never track main.
TOOLCHAIN_REF ?= v0.5
TC := .toolchain
ifeq (,$(wildcard $(TC)/chip.mk))
$(shell rm -rf $(TC); gh repo clone TuriChips/toolchain $(TC) -- -q --depth 1 --branch $(TOOLCHAIN_REF))
endif
# Pin check lives here, in the chip repo, so it also catches a stale .toolchain from before v0.4
# (whose chip.mk has no check). `make TOOLCHAIN_REF=` turns it off.
ifneq (,$(TOOLCHAIN_REF))
ifeq (,$(filter $(TOOLCHAIN_REF),$(shell git -C $(TC) tag --points-at HEAD 2>/dev/null)))
$(error toolchain mismatch: Makefile pins $(TOOLCHAIN_REF) but $(TC) is a different version. Run: rm -rf $(TC))
endif
endif
include $(TC)/chip.mk
