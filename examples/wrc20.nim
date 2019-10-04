## ewasm “WRC20” token contract coding challenge
## https://gist.github.com/axic/16158c5c88fbc7b1d09dfa8c658bc363

import ../eth_contracts

proc bigEndian64*(x: uint64): uint64 {.noinline.} =
  var x = (x and 0x00000000FFFFFFFF'u64) shl 32 or (x and 0xFFFFFFFF00000000'u64) shr 32
  x = (x and 0x0000FFFF0000FFFF'u64) shl 16 or (x and 0xFFFF0000FFFF0000'u64) shr 16
  x = (x and 0x00FF00FF00FF00FF'u64) shl 8  or (x and 0xFF00FF00FF00FF00'u64) shr 8
  x

template bigEndian64*(v: uint64, outp: var openArray[byte]) =
  cast[ptr uint64](addr outp[0])[] = bigEndian64(v)

template bigEndian64*[N: static int](v: array[N, byte]): uint64 =
  static: assert N >= sizeof(uint64)
  bigEndian64(cast[ptr uint64](addr v[0])[])

proc do_balance() =
  var address {.noinit.}: array[32, byte]
  callDataCopy(addr address, 4, 20)
  zeroMem(addr address[20], 32 - 20)

  var balance {.noinit.}: array[32, byte]
  storageLoad(address, addr balance)
  finish(addr balance, 8)

proc do_transfer() =
  var address {.noinit.}: array[32, byte]
  getCaller(addr address[0])
  zeroMem(addr address[20], 32 - 20)
  var value {.noinit.}: array[8, byte]
  callDataCopy(addr value, 24, 8)

  var balance {.noinit.}: array[32, byte]
  storageLoad(address, addr balance)

  var
    b = bigEndian64(balance)
    v = bigEndian64(value)

  if b < v:
    revert(nil, 0)

  b -= v

  bigEndian64(b, balance)
  storageStore(address, addr balance)

  callDataCopy(addr address, 4, 20)
  storageLoad(address, addr balance)

  b = bigEndian64(balance)
  b += v # TODO there's an overflow possible here..

  bigEndian64(b, balance)
  storageStore(address, addr balance)

proc main() {.exportwasm.} =
  var selector {.noinit.}: uint32
  callDataCopy(selector, 0)
  case selector
  of 0x1a029399'u32:
    do_balance()
  of 0xbd9f355d'u32:
    do_transfer()
  else:
    revert(nil, 0)
