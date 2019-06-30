L=/home/arnetheduck/src/nlvm/ext/llvm-8.0.0.src/sha/bin
NFLAGS=--checks:off --nlvm.target=wasm32-unknown-unknown --gc:none -l:--compress-relocations -l:--no-entry -l:--allow-undefined -l:--strip-all --noMain
B=/home/arnetheduck/src/binaryen/bin

.PHONY: all
all: wrc20.wat wrc20opt.wat wrc20opt.ll wrc20strip.wat wrc20binaryen.wat
	ls -l

wrc20opt.wasm: wrc20opt.ll
	$(L)/llc -filetype=obj -O2 wrc20opt.ll -o wrc20opt.o
	$(L)/wasm-ld -o wrc20opt.wasm wrc20opt.o -O2 --strip-all --no-entry --allow-undefined --export-dynamic --compress-relocations

wrc20.ll: wrc20.nim
	nlvm c $(NFLAGS) -c -d:release --opt:size wrc20

wrc20.wasm: wrc20.nim
	nlvm c $(NFLAGS) -d:release --opt:size wrc20

wrc20opt.ll: wrc20.ll
	$(L)/opt -O2 -disable-inlining wrc20.ll | $(L)/llvm-dis > wrc20opt.ll

.PHONY: clean
clean:
	rm -f *.wasm *.ll *.wat

%.wat: %.wasm
	wasm2wat --generate-names $< > $@

wrc20strip.wasm: wrc20opt.wat
	sed -e '/__heap_base\|__data_end\|funcref/d' -e 's/env/ethereum/g' wrc20opt.wat > wrc20tmp.wat
	wat2wasm -o wrc20strip.wasm wrc20tmp.wat

wrc20binaryen.wasm: wrc20strip.wasm
	$(B)/wasm-opt -Os -o wrc20binaryen.wasm wrc20strip.wasm
