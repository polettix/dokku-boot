#!/usr/bin/env perl
# *** NOTE *** LEAVE THIS MODULE LIST AS A PARAGRAPH
use strict;
use warnings;
use 5.006_002;
our $VERSION = '0.2.0';
use English qw( -no_match_vars );
use Fatal qw( close chdir opendir closedir );
use File::Temp qw( tempdir );
use File::Path qw( mkpath );
use File::Spec::Functions qw( file_name_is_absolute catfile );
use File::Basename qw( basename dirname );
use POSIX qw( strftime );
use Getopt::Long qw( :config gnu_getopt );
use Cwd qw( getcwd );
use Fcntl qw( :seek );

# *** NOTE *** LEAVE EMPTY LINE ABOVE
my %default_config = (    # default values
   workdir     => '/tmp',
   cleanup     => 1,
   'no-exec'   => 0,
   tempdir     => 1,
   passthrough => 0,
   verbose     => 0,
);

my $DATA_POSITION = tell DATA;                         # GLOBAL VARIABLE
my %script_config = (%default_config, get_config());

my %config = %script_config;
if ($ENV{DEPLOYABLE_DISABLE_PASSTHROUGH} || (!$config{passthrough})) {
   my %cmdline_config;
   GetOptions(
      \%cmdline_config,
      qw(
        usage|help|man!
        version!

        bundle|all-exec|X!
        cleanup|c!
        dryrun|dry-run|n!
        filelist|list|l!
        heretar|here-tar|H!
        inspect|i=s
        no-exec!
        no-tar!
        roottar|root-tar|R!
        show|show-options|s!
        tar|t=s
        tempdir!
        tempdir-mode|m=s
        verbose!
        workdir|work-directory|deploy-directory|w=s
        ),
   ) or short_usage();
   %config = (%config, %cmdline_config);
} ## end if ($ENV{DEPLOYABLE_DISABLE_PASSTHROUGH...})

usage()   if $config{usage};
version() if $config{version};

if ($config{roottar}) {
   binmode STDOUT;
   my ($fh, $size) = locate_file('root');
   copy($fh, \*STDOUT, $size);
   exit 0;
} ## end if ($config{roottar})

if ($config{heretar}) {
   binmode STDOUT;
   my ($fh, $size) = locate_file('here');
   copy($fh, \*STDOUT, $size);
   exit 0;
} ## end if ($config{heretar})

if ($config{show}) {
   require Data::Dumper;
   print {*STDOUT} Data::Dumper::Dumper(\%script_config);
   exit 1;
}

if ($config{inspect}) {
   $config{cleanup}   = 0;
   $config{'no-exec'} = 1;
   $config{'tempdir'} = 0;
   $config{workdir}   = $config{inspect};
} ## end if ($config{inspect})

if ($config{dryrun}) {
   require Data::Dumper;
   print {*STDOUT} Data::Dumper::Dumper(\%config);
   exit 1;
}

if ($config{filelist}) {
   my $root_tar = get_sub_tar('root');
   print "root:\n";
   $root_tar->print_filelist();
   my $here_tar = get_sub_tar('here');
   print "here:\n";
   $here_tar->print_filelist();
   exit 0;
} ## end if ($config{filelist})

# here we have to do things for real... probably, so save the current
# working directory for consumption by the scripts
$ENV{OLD_PWD} = getcwd();

# go into the working directory, creating any intermediate if needed
mkpath($config{workdir});
chdir($config{workdir});
print {*STDERR} "### Got into working directory '$config{workdir}'\n\n"
  if $config{verbose};

my $tempdir;
if ($config{'tempdir'}) {    # Only if allowed
   my $me = basename(__FILE__) || 'deploy';
   my $now = strftime('%Y-%m-%d_%H-%M-%S', localtime);
   $tempdir = tempdir(
      join('-', $me, $now, ('X' x 10)),
      DIR     => '.',
      CLEANUP => $config{cleanup}
   );

   if ($config{'tempdir-mode'}) {
      chmod oct($config{'tempdir-mode'}), $tempdir
        or die "chmod('$tempdir'): $OS_ERROR\n";
   }

   chdir $tempdir
     or die "chdir('$tempdir'): $OS_ERROR\n";

   if ($config{verbose}) {
      print {*STDERR}
        "### Created and got into temporary directory '$tempdir'\n";
      print {*STDERR} "### (will clean it up later)\n" if $config{cleanup};
      print {*STDERR} "\n";
   } ## end if ($config{verbose})
} ## end if ($config{'tempdir'})

eval {    # Not really needed, but you know...
   $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
   save_files();
   execute_deploy_programs() unless $config{'no-exec'};
};
warn "$EVAL_ERROR\n" if $EVAL_ERROR;

# Get back so that cleanup can successfully happen, if requested
chdir '..' if defined $tempdir;

sub locate_file {
   my ($filename) = @_;
   my $fh = \*DATA;
   seek $fh, $DATA_POSITION, SEEK_SET;
   while (!eof $fh) {
      chomp(my $sizes = <$fh>);
      my ($name_size, $file_size) = split /\s+/, $sizes;
      my $name = full_read($fh, $name_size);
      full_read($fh, 1);    # "\n"
      return ($fh, $file_size) if $name eq $filename;
      seek $fh, $file_size + 2, SEEK_CUR;    # includes "\n\n"
   } ## end while (!eof $fh)
   die "could not find '$filename'";
} ## end sub locate_file

sub full_read {
   my ($fh, $size) = @_;
   my $retval = '';
   while ($size) {
      my $buffer;
      my $nread = read $fh, $buffer, $size;
      die "read(): $OS_ERROR" unless defined $nread;
      die "unexpected end of file" unless $nread;
      $retval .= $buffer;
      $size -= $nread;
   } ## end while ($size)
   return $retval;
} ## end sub full_read

sub copy {
   my ($ifh, $ofh, $size) = @_;
   while ($size) {
      my $buffer;
      my $nread = read $ifh, $buffer, ($size < 4096 ? $size : 4096);
      die "read(): $OS_ERROR" unless defined $nread;
      die "unexpected end of file" unless $nread;
      print {$ofh} $buffer;
      $size -= $nread;
   } ## end while ($size)
   return;
} ## end sub copy

sub get_sub_tar {
   my ($filename) = @_;
   my ($fh, $size) = locate_file($filename);
   return Deployable::Tar->new(%config, fh => $fh, size => $size);
}

sub get_config {
   my ($fh, $size) = locate_file('config.pl');
   my $config_text = full_read($fh, $size);
   my $config = eval 'my ' . $config_text or return;
   return $config unless wantarray;
   return %$config;
} ## end sub get_config

sub save_files {
   my $here_tar = get_sub_tar('here');
   $here_tar->extract();

   my $root_dir = $config{inspect} ? 'root' : '/';
   mkpath $root_dir unless -d $root_dir;
   my $cwd = getcwd();
   chdir $root_dir;
   my $root_tar = get_sub_tar('root');
   $root_tar->extract();
   chdir $cwd;

   return;
} ## end sub save_files

sub execute_deploy_programs {
   my @deploy_programs = @{$config{deploy} || []};

   if ($config{bundle}) { # add all executable scripts in current directory
      print {*STDERR} "### Auto-deploying all executables in main dir\n\n"
        if $config{verbose};
      my %flag_for = map { $_ => 1 } @deploy_programs;
      opendir my $dh, '.';
      for my $item (sort readdir $dh) {
         next if $flag_for{$item};
         next unless ((-f $item) || (-l $item)) && (-x $item);
         $flag_for{$item} = 1;
         push @deploy_programs, $item;
      } ## end for my $item (sort readdir...)
      closedir $dh;
   } ## end if ($config{bundle})

 DEPLOY:
   for my $deploy (@deploy_programs) {
      $deploy = catfile('.', $deploy)
        unless file_name_is_absolute($deploy);
      if (!-x $deploy) {
         print {*STDERR} "### Skipping '$deploy', not executable\n\n"
           if $config{verbose};
         next DEPLOY;
      }
      print {*STDERR} "### Executing '$deploy'...\n"
        if $config{verbose};
      system {$deploy} $deploy, @ARGV;
      print {*STDERR} "\n"
        if $config{verbose};
   } ## end DEPLOY: for my $deploy (@deploy_programs)

   return;
} ## end sub execute_deploy_programs

sub short_usage {
   my $progname = basename($0);
   print {*STDOUT} <<"END_OF_USAGE" ;

$progname version $VERSION - for help on calling and options, run:

   $0 --usage
END_OF_USAGE
   exit 1;
} ## end sub short_usage

sub usage {
   my $progname = basename($0);
   print {*STDOUT} <<"END_OF_USAGE" ;
$progname version $VERSION

More or less, this script is intended to be launched without parameters.
Anyway, you can also set the following options, which will override any
present configuration (except in "--show-options"):

* --usage | --man | --help
    print these help lines and exit

* --version
    print script version and exit

* --bundle | --all-exec | -X
    treat all executables in the main deployment directory as scripts
    to be executed

* --cleanup | -c | --no-cleanup
    perform / don't perform temporary directory cleanup after work done

* --deploy | --no-deploy
    deploy scripts are executed by default (same as specifying '--deploy')
    but you can prevent it.

* --dryrun | --dry-run
    print final options and exit

* --filelist | --list | -l
    print a list of files that are shipped in the deploy script

* --heretar | --here-tar | -H
    print out the tar file that contains all the files that would be
    extracted in the temporary directory, useful to redirect to file or
    pipe to the tar program

* --inspect | -i <dirname>
    just extract all the stuff into <dirname> for inspection. Implies
    --no-deploy, --no-tempdir, ignores --bundle (as a consequence of
    --no-deploy), disables --cleanup and sets the working directory
    to <dirname>

* --no-tar
    don't use system "tar"

* --roottar | --root-tar | -R
    print out the tar file that contains all the files that would be
    extracted in the root directory, useful to redirect to file or
    pipe to the tar program

* --show | --show-options | -s
    print configured options and exit

* --tar | -t <program-path>
    set the system "tar" program to use.

* --tempdir | --no-tempdir
    by default a temporary directory is created (same as specifying
    '--tempdir'), but you can execute directly in the workdir (see below)
    without creating it.

* --tempdir-mode | -m
    set permissions of temporary directory (octal string)

* --workdir | --work-directory | --deploy-directory | -w
    working base directory (a temporary subdirectory will be created 
    there anyway)
    
END_OF_USAGE
   exit 1;
} ## end sub usage

sub version {
   print "$0 version $VERSION\n";
   exit 1;
}

package Deployable::Tar;

sub new {
   my $package = shift;
   my $self = {ref $_[0] ? %{$_[0]} : @_};
   $package = 'Deployable::Tar::Internal';
   if (!$self->{'no-tar'}) {
      if ((exists $self->{tar}) || (open my $fh, '-|', 'tar', '--help')) {
         $package = 'Deployable::Tar::External';
         $self->{tar} ||= 'tar';
      }
   } ## end if (!$self->{'no-tar'})
   bless $self, $package;
   $self->initialise() if $self->can('initialise');
   return $self;
} ## end sub new

package Deployable::Tar::External;
use English qw( -no_match_vars );

sub initialise {
   my $self = shift;
   my $compression =
       $self->{bzip2} ? 'j'
     : $self->{gzip}  ? 'z'
     :                  '';
   $self->{_list_command}    = 'tv' . $compression . 'f';
   $self->{_extract_command} = 'x' . $compression . 'f';
} ## end sub initialise

sub print_filelist {
   my $self = shift;
   if ($self->{size}) {
      open my $tfh, '|-', $self->{tar}, $self->{_list_command}, '-'
        or die "open() on pipe to tar: $OS_ERROR";
      main::copy($self->{fh}, $tfh, $self->{size});
   }
   return $self;
} ## end sub print_filelist

sub extract {
   my $self = shift;
   if ($self->{size}) {
      open my $tfh, '|-', $self->{tar}, $self->{_extract_command}, '-'
        or die "open() on pipe to tar: $OS_ERROR";
      main::copy($self->{fh}, $tfh, $self->{size});
   }
   return $self;
} ## end sub extract

package Deployable::Tar::Internal;
use English qw( -no_match_vars );

sub initialise {
   my $self = shift;

   if ($self->{size}) {
      my $data = main::full_read($self->{fh}, $self->{size});
      open my $fh, '<', \$data
        or die "open() on internal variable: $OS_ERROR";

      require Archive::Tar;
      $self->{_tar} = Archive::Tar->new();
      $self->{_tar}->read($fh);
   } ## end if ($self->{size})

   return $self;
} ## end sub initialise

sub print_filelist {
   my $self = shift;
   if ($self->{size}) {
      print {*STDOUT} "   $_\n" for $self->{_tar}->list_files();
   }
   return $self;
} ## end sub print_filelist

sub extract {
   my $self = shift;
   if ($self->{size}) {
      $self->{_tar}->extract();
   }
   return $self;
} ## end sub extract

__END__
9 139
config.pl
$VAR1 = {
          'deploy' => [
                        'dokku-boot.sh'
                      ],
          'passthrough' => 0
        };


4 20480
here
dokku-boot.d/                                                                                       0000755 0001751 0001751 00000000000 13314000471 013273  5                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                dokku-boot.d/01.upgrade-debian.sh                                                                   0000755 0001751 0001751 00000000150 12775205734 016737  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash
set -eo pipefail
apt-get -y update || { sleep 5 && apt-get -y update ; }
apt-get -y upgrade
                                                                                                                                                                                                                                                                                                                                                                                                                        dokku-boot.d/10.setup-swap.sh                                                                       0000755 0001751 0001751 00000000642 13013716625 016176  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

# create swap file only if really necessary
FREE_MEMORY=$(grep MemTotal /proc/meminfo | awk '{print $2}')
[ "$FREE_MEMORY" -lt 1003600 ] || exit 0

# avoid creating it over and over
IMG='/var/swap.img'
[ -e "$IMG" ] && exit 0

# do the thing
touch "$IMG"
chmod 600 "$IMG"
dd if=/dev/zero of="$IMG" bs=1024k count=1000
mkswap "$IMG"
swapon "$IMG"

echo "$IMG    none    swap    sw    0    0" >> /etc/fstab
                                                                                              dokku-boot.d/20.install-dokku.sh                                                                    0000755 0001751 0001751 00000000634 13313743164 016652  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

id dokku >/dev/null 2>&1 && exit 0

if [ -z "$DOKKU_TAG" ] ; then
   DOKKU_TAG="$(
      curl https://raw.githubusercontent.com/dokku/dokku/master/README.md \
      | sed -n 's#wget https://.*/dokku/\(v.*\)/bootstrap.sh#\1#p'
   )"
fi

export DOKKU_TAG
wget https://raw.githubusercontent.com/dokku/dokku/"$DOKKU_TAG"/bootstrap.sh
bash bootstrap.sh

"$(dirname "$0")/00.setup-iptables.sh" regenerate
                                                                                                    dokku-boot.d/21.install-plugins.sh                                                                  0000755 0001751 0001751 00000000550 12775206174 017222  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

BASE='/var/lib/dokku/plugins/available'

[ -e "$BASE/letsencrypt" ] \
   || dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
[ -e "$BASE/postgres" ] \
   || dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres
[ -e "$BASE/redis" ] \
   || dokku plugin:install https://github.com/dokku/dokku-redis.git redis
                                                                                                                                                        dokku-boot.d/00.setup-iptables.sh                                                                   0000755 0001751 0001751 00000006045 13313745134 017031  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

set -eo pipefail

base_rules_ipv4() {
   cat <<END
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth0    -p icmp --icmp-type echo-request -m limit --limit 2/second -j ACCEPT
-A INPUT -i eth0    -p tcp -m tcp --dport    22 -j ACCEPT 
-A INPUT -i eth0    -p tcp -m tcp --dport    80 -j ACCEPT 
-A INPUT -i eth0    -p tcp -m tcp --dport   443 -j ACCEPT 
-A INPUT -i docker0 -p tcp -m tcp --dport    80 -j ACCEPT 
-A INPUT -i docker0 -p tcp -m tcp --dport   443 -j ACCEPT 
-A OUTPUT -s 127.0.0.1 -j ACCEPT
END
}

base_rules_ipv6() {
   cat <<END
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
-A INPUT -i lo -j ACCEPT 
-A INPUT -i eth0    -p icmpv6 -m limit --limit 2/second -j ACCEPT
-A INPUT -i eth0    -p tcp    -m tcp   --dport       22 -j ACCEPT 
-A INPUT -i eth0    -p tcp    -m tcp   --dport       80 -j ACCEPT 
-A INPUT -i eth0    -p tcp    -m tcp   --dport      443 -j ACCEPT 
-A INPUT -i docker0 -p tcp    -m tcp   --dport       80 -j ACCEPT 
-A INPUT -i docker0 -p tcp    -m tcp   --dport      443 -j ACCEPT 
-A OUTPUT -s ::1 -j ACCEPT
END
}

ipv4_ips() {
   local IP
   for IP in $(hostname -I) ; do printf '%s\n' "$IP" ; done | grep -v ':'
}

ipv6_ips() {
   local IP
   for IP in $(hostname -I) ; do printf '%s\n' "$IP" ; done | grep ':'
}

ensure_rules() {
   local N_IP=$("$IPS" | wc -w)
   [ "$N_IP" -gt 0 ] || return 0

   local RELOAD=''

   if [ -n "$REGEN_RULES" -o ! -e "$RULES" ] ; then
      {
         "$BASE_RULES"

         local IP
         for IP in "$IPS" ; do
            printf '%s\n' "-A OUTPUT -s $IP -j ACCEPT"

            if [ -n "$REGEN_RULES" ] ; then
               local eip="$(printf '%s' "$IP" | sed -e 's/\./[.]/g')"
               if ! "$IPTABLES" -S OUTPUT | grep " $eip/" >/dev/null 2>&1
               then
                  # rule is not present, add it
                  "$IPTABLES" -A OUTPUT -S "$IP" -j ACCEPT
               fi
            fi >/dev/null 2>&1
         done

         "$IPS" | sed -e 's/^\(.*\)/-A OUTPUT -s \1 -j ACCEPT/'
         printf 'COMMIT\n'
      } >"$RULES.tmp"
      mv "$RULES.tmp" "$RULES"
      [ -z "$REGEN_RULES" ] && RELOAD=1
   fi

   if [ ! -e "$IFUP" ] ; then
      cat >"$IFUP.tmp" <<END
#!/bin/sh
"$IPTABLES-restore" <"$RULES"
END
      chmod +x "$IFUP.tmp"
      mv "$IFUP.tmp" "$IFUP"
   fi

   [ -z "$RELOAD" ] && return 0
   sh "$IFUP"
}

IPV=ipv4 \
   REGEN_RULES="$1"                     \
   RULES='/etc/network/iptables.rules'  \
   IPTABLES=iptables                    \
   BASE_RULES=base_rules_ipv4           \
   IPS=ipv4_ips                         \
   IFUP='/etc/network/if-up.d/iptables' \
      ensure_rules

IPV=ipv6 \
   REGEN_RULES="$1"                      \
   RULES='/etc/network/ip6tables.rules'  \
   IPTABLES=ip6tables                    \
   BASE_RULES=base_rules_ipv6            \
   IPS=ipv6_ips                          \
   IFUP='/etc/network/if-up.d/ip6tables' \
      ensure_rules

exit 0
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           dokku-boot.d/30.trivial-index.sh                                                                    0000755 0001751 0001751 00000000320 13014311571 016630  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

cat >'/var/www/html/index.html' <<'END'
<!DOCTYPE html>
<html>
   <head>
      <title>Black</title>
      <style>body { background-color: black } </style>
   </head>
   <body></body>
</html>
END
                                                                                                                                                                                                                                                                                                                dokku-boot.sh                                                                                       0000755 0001751 0001751 00000000465 13313736112 013424  0                                                                                                    ustar   poletti                         poletti                                                                                                                                                                                                                #!/bin/bash

set -eo pipefail

ME="$(readlink -f "$0")"
MD="$(dirname "$ME")"
SD="$MD/$(basename "$ME" .sh).d"

[ -r "$OLD_PWD/env.sh" ] && . "$OLD_PWD/env.sh"

find "$SD" -type f -executable \
   | LC_ALL=C sort             \
   | while read S ; do
      printf >&2 '%s\n' "$S"
      "$S" </dev/null
   done
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           

4 0
root


