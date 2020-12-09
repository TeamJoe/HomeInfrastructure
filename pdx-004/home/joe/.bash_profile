#!/bin/bash

export GOPATH=$HOME/.go
export PATH=$PATH:$GOPATH/bin

atm3() {
	sudo -u minecraft /home/minecraft/ATM3Server.sh "$@"
}

atm5() {
	sudo -u minecraft /home/minecraft/ATM5Server.sh "$@"
}

vanilla15() {
	sudo -u minecraft /home/minecraft/VanillaServer.sh "$@"
}

vanilla16() {
	sudo -u minecraft /home/minecraft/Vanilla-1-16.sh "$@"
}

rl() {
	sudo -u minecraft /home/minecraft/RLCraftServer.sh "$@"
}

sky() {
	sudo -u minecraft /home/minecraft/SkyFactory4Server.sh "$@"
}

sev() {
	sudo -u minecraft /home/minecraft/SevTechServer.sh "$@"
}

dst() {
	sudo -u steam /home/steam/dst-master.sh "$@"
}

caves() {
	sudo -u steam /home/steam/dst-caves.sh "$@"
}
