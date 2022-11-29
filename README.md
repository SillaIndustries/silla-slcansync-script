# silla-slcansync-script

A script in Nim language that retrieve the secrets from a particular partition by SLCAN.
The secrets are a list of credetianls (and serial code) and there are specific for every serial. The secrets size is 4096 byte.

## Compile

First of all, use the command: 
```
nimble install 
```

in the root of project dir to install the dependencies packages from **sillaslcansync.nimble** file

Then, use the below script to create the **sillaslcansync** bin in the **out**  dir.

For your local PC:
```
./compile-local.sh
```
For Mispel:
```
./compile-misp.sh
```

## How it works

This script use the  **/dev/ttyS1** serial to open a communIcation with ClusterBase and retrieve the partition that contains the secrets. 

To do this, the script send a message named **K\r\n** for the scope to trigger ClusterBase for sending partition secrets.

Then, the script will expect 512 packages with the following structure:

```
*KAAALDDDDDDDDDDDDDDDD*
```
Where:
```
*K* - Command
*A* - Packet address (from 0 to FF8)
*L* - Packet data length (8 Bytes)
*D* - Data Byte
```
Every message is composed by 21 character.

After that, if the the script received all the 512 expected packages, it can rebuild the partition with the data byte and the address information.

At last, save the partition in a bin file named **/tmp/secrets.bin**