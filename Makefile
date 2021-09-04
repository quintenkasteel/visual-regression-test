help:
	@echo "check"

generate:
	@echo "Initializing..."
	@stack install --pedantic --ghc-options "-j8 +RTS -A128m -n2m -RTS" && \
	 stack runghc --package ansi-terminal -- -isrc generate.hs

gen:
	@echo "Initializing..."
	@stack install --pedantic --ghc-options "-j8 +RTS -A128m -n2m -RTS" && \
	 stack runghc --package ansi-terminal -- -isrc gen.hs