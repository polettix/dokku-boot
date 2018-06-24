pack:: dokku-boot.pl

dokku-boot.pl: dokku-boot.sh dokku-boot.d/*.sh
	rm -f dokku-boot.pl
	deployable                          \
		dokku-boot.d                     \
		dokku-boot.sh -d dokku-boot.sh   \
		| sed -e "0,/^our \$$VERSION/s/^our \$$VERSION.*/our \$$VERSION = '$$(date +"%Y%m%d.%H%M%S")';/"          \
		> dokku-boot.pl
	chmod +x dokku-boot.pl
