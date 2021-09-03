help:
	@echo "check"

generate:
	@echo "Initializing..."
	@stack runghc --package ansi-terminal -- -isrc generate.hs