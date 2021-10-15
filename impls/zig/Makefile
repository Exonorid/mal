STEPS = step0_repl

all: $(STEPS)

dist: mal

mal: stepA_mal
	cp $< $@

%: %.zig
	zig build $* -Drelease-fast --cache-dir ../../.cache/zig
	cp zig-out/bin/$@ .

.PHONY: clean

clean:
	rm -rf zig-out
	rm -f $(STEPS)
	rm -f mal
