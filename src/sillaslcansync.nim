import serial, sequtils, strutils, strformat, streams, times, os

const serialName = "/dev/ttyS1"
const baudRate = 115200
const parity = Parity.None
const numBit = 8
const stopBit = StopBits.One

const expectedPackets = 512 # number of packet
const packetLen = 21 # bytes
const timeMaxSerial = 7 # seconds

const binFilePath = "/tmp/secrets.bin"
 
type
  PacketK* = ref object
    address*: int             # position to begin the write of dataBytes
    numBytes*: int            # number of bytes to write
    dataBytes*: seq[uint8]    # the data bytes


# Check the availability of the serial port. Mysteriously it doesn't work
proc checkSerial(serialName: string): bool =  
  let serialPorts = toSeq(listSerialPorts())

  echo "Serial Ports"
  echo "------------"

  for i in low(serialPorts)..high(serialPorts):
    echo "[", i, "] ", serialPorts[i]
    if serialName == serialPorts[i]:
      return true
  return false  


# Parse the message receive from serial into a proper type
proc parsePacketK(msx: string): PacketK =
  #      KAAALDDDDDDDDDDDDDDDD
  # e.g. K01081680fbd95fd10ffb
  # where:
  #   K - Command
  #   A - Packet address (from 0 to FF8)
  #   L - Packet data length (8 Bytes)
  #   D - Data Byte

  let address = parseHexInt(fmt"0{msx[1 .. 3]}")
  let numBytes = parseInt(fmt"{msx[4]}")
  let dataChar = msx[5 .. ^1]
  var dataBytes: seq[uint8]
    
  for i in 0 .. (numBytes - 1):
    dataBytes.add(uint8(parseHexInt(dataChar[2*i .. 2*i+1])))

  return PacketK(address: address, numBytes: numBytes, dataBytes: dataBytes) 


# Creation of bin File from a list of K message. 
proc manageSecrets(messages: seq[string]) =
  
  var binFile : array[4096, uint8]

  for msx in messages:
    let packet = parsePacketK(msx)
    
    for i in 0 .. packet.numBytes - 1:
      binFile[packet.address + i] = packet.dataBytes[i]
  
  let f = open(binFilePath, fmWrite)
  defer: f.close()
  
  discard f.writeBytes(binFile, 0, 4096)


proc main() =
  #if not checkSerial(serialName):
  #  echo fmt"The port {serialName} isn't available. Exit"
  #  quit(QuitFailure)

  let serialPort = newSerialStream(serialName, baudRate, parity, numBit, stopBit, Handshake.None, buffered=false)
  defer: close(serialPort)
  #serialPort.setTimeouts(5000, 500)
  var secrets : seq[string]

  discard tryRemoveFile(binFilePath)

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
    echo "Procedure Complete!"
  else:  
    echo fmt"Warning! We received only {secrets.len} of {expectedPackets} expected! Can't created the secrets bin!"


# Use for test the parsing of Packet K
proc testParsePacketK(msx:string): void =
  let packet = parsePacketK(msx)
  echo fmt" message: {msx}"
  echo fmt" address: {packet.address}"
  echo fmt" numBytes: {packet.numBytes}"
  echo fmt" dataBytes: {packet.dataBytes}"


when isMainModule:
  main()