pack:: dokku-boot.pl

dokku-boot.pl: *.sh
	rm -f dokku-boot.pl
	deployable -o dokku-boot.pl         \
		dokku-boot                       \
		dokku-debian.sh -d dokku-boot.sh
	chmod +x dokku-debian.pl
