#!/usr/bin/bash

DEST_PATH="../makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl"
CURRENT_PATH=$(pwd)

cd $DEST_PATH
# Run commands
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -i 1443:0007
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 -p J:D0D2D3D4:fpga.xsvf
sudo ../../../../../../apps/flcli/lin.x64/rel/flcli -v 1d50:602b:0002 --custom track_data.csv
cd $CURRENT_PATH
