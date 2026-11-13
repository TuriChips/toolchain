# Included by a chip repo's Makefile. TC = toolchain checkout dir.
TC ?= .toolchain
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
