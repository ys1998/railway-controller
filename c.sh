#!/usr/bin/bash

MAIN_PATH=$(realpath "../makestuff/apps/flcli")
LIB_PATH=$(realpath "../makestuff/libs")
CURRENT_PATH=$(pwd)

# Copy main.c file
cp -f ./host/main.c $MAIN_PATH
cp -f ./host/new_utilities.h $MAIN_PATH
# Copy track_data.csv file
cp -f ./host/track_data.csv $MAIN_PATH

# Copy libraries
cp -f ./host/libfpgalink.* $LIB_PATH/libfpgalink
cp -f ./host/libusbwrap.* $LIB_PATH/libusbwrap

# Update path of track_data.csv in main.c
NEW_PATH=$(realpath $MAIN_PATH/track_data.csv)
sed -i "921s@.*@\t\t\tchar\*\ dataFile\ \=\ \"$NEW_PATH\";@g" $MAIN_PATH/main.c

# Call makefiles
cd $LIB_PATH/libusbwrap/
make clean; make deps
cd $LIB_PATH/libfx2loader
make clean; make deps
cd $LIB_PATH/libfpgalink
make clean; make deps
cd $MAIN_PATH
make clean; make deps

cd $CURRENT_PATH

