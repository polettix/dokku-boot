pack:: dokku-debian.pl

all:: pack push

dokku-debian.pl: *.sh
	rm -f dokku-debian.pl
	deployable -o dokku-debian.pl *.sh -d dokku-debian.sh
	chmod +x dokku-debian.pl

push::
	scp dokku-debian.pl rdodokku:
