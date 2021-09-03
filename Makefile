help:
	@echo "check"

generate:
	@echo "Initializing..."
	@stack runghc --package ansi-terminal -- -isrc generate.hs

stack-install:
	@stack clean && stack install --pedantic --ghc-options "-j8 +RTS -A128m -n2m -RTS"