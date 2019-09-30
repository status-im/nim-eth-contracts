L=/home/arnetheduck/src/nlvm/ext/llvm-8.0.0.src/sha/bin
NFLAGS=--checks:off --nlvm.target=wasm32-unknown-unknown --gc:none -l:--no-entry -l:--allow-undefined --noMain
B=/home/arnetheduck/src/binaryen/bin

.PHONY: all
all: wrc20.wat wrc20opt.wat wrc20opt.ll wrc20strip.wat wrc20binaryen.wat
	du -b wrc20binaryen.wasm wrc20opt.wasm wrc20.wasm
	twiggy top -n 20 wrc20binaryen.wasm
	twiggy top -n 20 wrc20.wasm
	twiggy top -n 20 wrc20opt.wasm

wrc20opt.wasm: wrc20opt.ll
	-cp wrc20opt.wasm wrc20opt.prev.wasm
	$(L)/llc -filetype=obj -O3 wrc20opt.ll -o wrc20opt.o
	$(L)/wasm-ld -o wrc20opt.wasm wrc20opt.o -O3 --no-entry --allow-undefined --export-dynamic

wrc20.ll: wrc20.nim Makefile ../eth_contracts.nim
	-cp wrc20.ll wrc20.prev.ll
	nlvm c $(NFLAGS) -c wrc20

wrc20.wasm: wrc20.nim Makefile  ../eth_contracts.nim
	-cp wrc20.wasm wrc20.prev.wasm
	nlvm c $(NFLAGS) wrc20

wrc20opt.ll: wrc20.ll
	-cp wrc20opt.ll wrc20opt.prev.ll
	$(L)/opt -Oz wrc20.ll | $(L)/llvm-dis > wrc20opt.ll

.PHONY: clean
clean:
	rm -f *.wasm *.ll *.wat

%.wat: %.wasm
	-cp $@ $(@:.wat=.prev.wat)
	wasm2wat --generate-names $< > $@

wrc20strip.wasm: wrc20opt.wat
	-cp wrc20strip.wasm wrc20strip.prev.wasm
	sed -e '/__heap_base\|__data_end\|funcref/d' -e 's/env/ethereum/g' wrc20opt.wat > wrc20tmp.wat
	wat2wasm -o wrc20strip.wasm wrc20tmp.wat

wrc20binaryen.wasm: wrc20strip.wasm
	-cp wrc20binaryen.wasm wrc20binaryen.prev.wasm
	$(B)/wasm-opt -Oz -o wrc20binaryen.wasm wrc20strip.wasm
