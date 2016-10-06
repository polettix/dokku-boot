pack:: dokku-debian.pl

dokku-debian.pl: *.sh
	rm -f dokku-debian.pl
	deployable -o dokku-debian.pl *.sh -d dokku-debian.sh
	chmod +x dokku-debian.pl
