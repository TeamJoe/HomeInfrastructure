#!/bin/bash

export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

satisfactory1() {
	sudo -u satisfactory /home/satisfactory/satisfactory.sh "$@"
}

satisfactory2() {
	sudo -u satisfactory /home/satisfactory/satisfactory2.sh "$@"
}
