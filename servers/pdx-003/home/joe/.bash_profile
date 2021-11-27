#!/bin/bash

export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

satisfactory() {
	sudo -u satisfactory /home/satisfactory/satisfactory.sh "$@"
}

