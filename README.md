# Get Me Started, Fast!

As easy as one, two, three:

1. Spin up a new VPS somewhere, e.g. [DigitalOcean][]. I usually choose
   the latest Debian release. You can select the smallest size if you just
   want to give it a try. (And please... set up and use SSH keys, it's
   2016 or later!). Let's say we save the IP address of this VPS in
   variable `DOKKU_IP`

2. Log in a shell in the VPS and run:

        curl https://github.com/polettix/dokku-boot/raw/master/dokku-boot.pl \
            | perl

3. Wait for installation to complete, then go to `http://$DOKKU_IP/` and
   complete the setup of [Dokku][].

# What now?

You can use [Dokku][] on the VPS you just configured.

Want an example? In your terminal:

    # Of course, substitute your-vps-ip with... your VPS IP Address or
    # your VPS DNS name
    $ DOKKU_HOST='your-vps-ip'

    # Create application in dokku
    $ ssh "dokku@$DOKKU_HOST" apps:create sample-mojo

    # Get something to play with
    $ git clone https://github.com/polettix/sample-mojo.git sample-mojo
    $ cd sample-mojo
    $ git remote add dokku "dokku@$DOKKU_HOST:sample-mojo"
    
    # Have fun!
    $ git push --set-upstream dokku master

Wait for the magic to happen... and enjoy your new shiny application at
the address printed around the end of the last command.

# Bootstrap Dokku

Do you know [Dokku][]? They dub it as *The smallest PaaS implementation
you've ever seen*, and well... it really is.

It's easy to install. But but... this only gets you started. I wanted
something that:

- would be easy to run in a newly spawned VPS (e.g. in [DigitalOcean][])
- would also care to set up reasonable firewalling rules:
    - leave only ports `22`, `80` and `443` open
    - put sane restrictions on forwarding and output
- last, would install a few plugins I want to have around:
    - [letsencrypt][] to automate handling of *real* TLS certificates from
      [Let's Encrypt][]
    - [redis][]
    - [postgres][]


[Dokku]: http://dokku.viewdocs.io/dokku/
[DigitalOcean]: https://www.digitalocean.com/
[letsencrypt]: https://github.com/dokku/dokku-letsencrypt
[redis]: https://github.com/dokku/dokku-redis
[postgres]: https://github.com/dokku/dokku-postgres
[Let's Encrypt]: https://letsencrypt.org/
[deployable]: http://repo.or.cz/deployable.git
