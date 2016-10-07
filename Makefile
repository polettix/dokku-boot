pack:: dokku-boot.pl

dokku-boot.pl: dokku-boot.d/*.sh
	rm -f dokku-boot.pl
	deployable -o dokku-boot.pl         \
		dokku-boot.d                     \
		dokku-boot.sh -d dokku-boot.sh
	chmod +x dokku-boot.pl
