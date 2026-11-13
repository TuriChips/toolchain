# Included by a chip repo's Makefile. TC = toolchain checkout dir.
TC ?= .toolchain
# Fail if the checkout at $(TC) is not the tag the chip pinned (stale or CI-provided checkout).
ifneq (,$(TOOLCHAIN_REF))
TC_HAVE := $(shell git -C $(TC) describe --tags --exact-match 2>/dev/null)
ifneq ($(TC_HAVE),$(TOOLCHAIN_REF))
$(error toolchain mismatch: Makefile pins $(TOOLCHAIN_REF) but $(TC) is at '$(TC_HAVE)'. Bump both TOOLCHAIN_REF and the @tag in .github/workflows/ci.yml together, and `rm -rf $(TC)`)
endif
endif
.PHONY: all test synth tools clean
all: tools test synth
tools:
	@$(TC)/scripts/versions.sh
test:
	@$(TC)/scripts/run_tests.sh $(BLOCK)
synth:
	@$(TC)/scripts/synth.sh $(BLOCK)
clean:
	rm -rf build
