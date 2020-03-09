#!/bin/bash

atm3() {
	sudo -u minecraft /home/minecraft/ATM3Server.sh "$@"
}

atm5() {
	sudo -u minecraft /home/minecraft/ATM5Server.sh "$@"
}

vanilla() {
	sudo -u minecraft /home/minecraft/VanillaServer.sh "$@"
}

dst() {
	sudo -u steam /home/steam/dst-master.sh "$@"
}

caves() {
	sudo -u steam /home/steam/dst-caves.sh "$@"
}
