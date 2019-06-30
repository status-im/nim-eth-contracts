## ewasm “WRC20” token contract coding challenge
## https://gist.github.com/axic/16158c5c88fbc7b1d09dfa8c658bc363

## updated by poemm here:
## https://discuss.status.im/t/wrc20-and-nim-the-ewasm-token-challenge/1167/11

import ../eth_contracts

proc bigEndian64*(x: uint64): uint64 {.noinline.} =
  # If we use inliner or enable the bswap intrinsic, code size explodes as wasm
  # lacks a bswap instruction
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
  if getCallDataSize() != 24:
    revert(nil, 0)

  var address{.noinit.}: array[32, byte]
  callDataCopy(address, 4, 20)

  var balance{.noinit.}: array[32, byte]
  storageLoad(address, balance)
  finish(addr balance, 8)

proc do_transfer() =
  if getCallDataSize() != 32:
    revert(nil, 0)

  var sender{.noinit.}: array[32, byte]
  getCaller(sender)
  var recipient{.noinit.}: array[32, byte]
  callDataCopy(recipient, 4, 20)
  var value: array[8, byte]
  callDataCopy(value, 24)

  var senderBalance{.noinit.}: array[32, byte]
  storageLoad(sender, senderBalance)
  var recipientBalance{.noinit.}: array[32, byte]
  storageLoad(recipient, recipientBalance)

  var
    sb = bigEndian64(senderBalance)
    v = bigEndian64(value)

  if sb < v:
    revert(nil, 0)

  var
    rb = bigEndian64(recipientBalance)

  sb -= v
  rb += v # TODO there's an overflow possible here..

  bigEndian64(sb, senderBalance)
  bigEndian64(rb, recipientBalance)

  storageStore(sender, senderBalance)
  storageStore(recipient, recipientBalance)

proc main() {.exportwasm.} =
  if getCallDataSize() < 4:
    revert(nil, 0)
  var selector: uint32
  callDataCopy(selector, 0)
  case selector
  of 0x1a029399'u32:
    do_balance()
  of 0xbd9f355d'u32:
    do_transfer()
  else:
    revert(nil, 0)
