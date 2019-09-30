## ewasm “WRC20” token contract coding challenge
## https://gist.github.com/axic/16158c5c88fbc7b1d09dfa8c658bc363

import ../eth_contracts, stint, endians

proc do_balance() =
  if getCallDataSize() != 24:
    revert(nil, 0)

  var address: array[32, byte]
  callDataCopy(addr address, 4, 20)

  var balance: array[32, byte]
  storageLoad(address, addr balance)
  finish(addr balance, 8)

proc do_transfer() =
  if getCallDataSize() != 32:
    revert(nil, 0)

  var sender: array[32, byte]
  getCaller(addr sender[0])
  var recipient: array[32, byte]
  callDataCopy(addr recipient, 4, 20)
  var value: array[16, byte]
  callDataCopy(addr value, 24, 8)

  var senderBalance: array[32, byte]
  storageLoad(sender, addr senderBalance)
  var recipientBalance: array[32, byte]
  storageLoad(recipient, addr recipientBalance)

  var
    sb = readUintBE[128](senderBalance)
    rb = readUintBE[128](recipientBalance)
    v = readUintBE[128](value)

  if sb < v:
    revert(nil, 0)

  sb -= v
  rb += v # TODO there's an overflow possible here..

  senderBalance[0..14] = sb.toByteArrayBE()
  recipientBalance[0..14] = rb.toByteArrayBE()

  storageStore(sender, addr senderBalance)
  storageStore(recipient, addr recipientBalance)

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
