import serial, sequtils, strutils, strformat, streams, times, sequtils

const baudRate = 115200
const parity = Parity.None
const numBit = 8
const stopBit = StopBits.One

const expectedPackets = 512 # number of packet
const packetLen = 21 # bytes
const timeMaxSerial = 7 # seconds
 

proc checkSerial(serialName: string): bool =  
  let serialPorts = toSeq(listSerialPorts())

  echo "Serial Ports"
  echo "------------"

  for i in low(serialPorts)..high(serialPorts):
    echo "[", i, "] ", serialPorts[i]
    if serialName == serialPorts[i]:
      return true
  return false  


proc convertCharToHex(cHex: string): uint8 =
  return (uint8) parseHexInt(cHex) 


#      KAAALDDDDDDDDDDDDDDDD
# e.g. K01081680fbd95fd10ffb
# where:
#   K - Command
#   A - Packet address (from 0 to FF8)
#   L - Packet data length (8 Bytes)
#   D - Data Byte
proc manageSecrets(messages: seq[string]) =
  
  var binFile : array[4096, uint8]

  for msx in messages:
    echo msx
    # WIP
    # let address = parseHexInt(fmt"0{msx[1 .. 3]}")
    # let dataLen = parseInt(fmt"{msx[4]}")
    # let data = msx[5 .. ^1]

    # echo address
    # echo dataLen
    # echo data

    # for i in 0 .. dataLen-1:
    #   echo parseHexInt(data[i .. i+1])


proc main() =
  let serialName = "/dev/ttyS1"
  #if not checkSerial(serialName):
  #  echo fmt"The port {serialName} isn't available. Exit"
  #  quit(QuitFailure)

  let serialPort = newSerialStream(serialName, baudRate, parity, numBit, stopBit, Handshake.None, buffered=false)
  defer: close(serialPort)
  #serialPort.setTimeouts(5000, 500)
  var secrets : seq[string]

  serialPort.writeLine("K\r\n")
  echo "Sending K message"
  let sendKTimestamp = toUnix(getTime())

  while true:
      let s = serialPort.readLine()

      if s[0] == 'K' and s.len == packetLen:
        # It's a K packet!
        secrets.add(s)

      if toUnix(getTime())  > sendKTimestamp + timeMaxSerial:
        break

  serialPort.close()

  if secrets.len == expectedPackets:
    echo "Received all packets!"
    manageSecrets(secrets)
  else:  
    echo fmt"Warning! We received only {secrets.len} of {expectedPackets} expected! Can't created the secrets bin!"
   

when isMainModule:
  main()
  # WIP
  #var test = @["K00880203ed9c5bafa2c8"]
  #manageSecrets(test)