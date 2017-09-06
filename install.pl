#!/bin/bash
source ./config.cfg

BIN=$DEST/bin
mkdir -p $DEST
mkdir -p $BIN

cp -Rp src/* $BIN
cp config.cfg $BIN

