#!/usr/bin/bash

CURRENT_PATH=$(pwd)
VHDL_PATH="../makestuff/hdlmake/apps/makestuff/swled/cksum/vhdl"
UCF_PATH="../makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/boards/atlys"
MODULE_PATH="../makestuff/hdlmake/apps/makestuff/swled/templates/fx2all/vhdl"
HARNESS_PATH="../makestuff/hdlmake/apps/makestuff/swled/templates"

# Copy files
cp -f ./fpga/cksum_rtl.vhdl $VHDL_PATH
cp -f ./fpga/harness.vhdl $HARNESS_PATH
cp -f ./fpga/modules/* $MODULE_PATH
cp -f ./fpga/board.ucf $UCF_PATH

# Compile VHDL code
cd $VHDL_PATH
sudo "PATH=$PATH" python2 ../../../../../bin/hdlmake.py -t ../../templates/fx2all/vhdl -b atlys -p fpga
cd $CURRENT_PATH

