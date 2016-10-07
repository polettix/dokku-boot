# Get Me Started, Fast!

As easy as one, two, three:

1. Spin up a new VPS somewhere, e.g. [DigitalOcean][]. I usually choose
   the latest Debian release. You can select the smallest size if you just
   want to give it a try. (And please... set up and use SSH keys, it's
   2016 or later!). Let's say we save the IP address of this VPS in
   variable `DOKKU_IP`

2. Log in a shell in the VPS as user `root` and run:

        curl -LO https://github.com/polettix/dokku-boot/raw/master/dokku-boot.pl
        perl dokku-boot.pl

3. Wait for installation to complete, then go to `http://$DOKKU_IP/` and
   complete the setup of [Dokku][].

# What now?

We will suppose that your VPS has FQDN `foobar.example.com`.

In your terminal:

    $ DOKKU_HOST='foobar.example.com'

    # Create application in dokku
    $ ssh "dokku@$DOKKU_HOST" apps:create sample-mojo
    # ... probably some stuff that has to do with SSH, just say yes
    Creating sample-mojo... done

    # Get something to play with
    $ git clone https://github.com/polettix/sample-mojo.git sample-mojo
    Cloning into 'sample-mojo'...
    remote: Counting objects: 6, done.
    remote: Compressing objects: 100% (4/4), done.
    remote: Total 6 (delta 0), reused 6 (delta 0), pack-reused 0 Unpacking
    objects: 100% (6/6), done.

    $ cd sample-mojo

    $ git remote add dokku "dokku@$DOKKU_HOST:sample-mojo"
    
    # Have fun!
    $ git push --set-upstream dokku master
    Counting objects: 6, done.
    # ... several lines of automated deployment...
    =====> Application deployed:
           http://sample-mojo.foobar.example.com

    To dokku@foobar.introm.it:sample-mojo
    * [new branch]      master -> master
    Branch master set up to track remote branch master from dokku.

    # Now enjoy your new application, use URL provided after line
    #
    # =====> Application deployed:
    #
    # above
    $ curl http://sample-mojo.foobar.example.com
    Hello, World!

# I'm Ready For Some Details Now!

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

This is what `dokku-boot` is about.

[Dokku]: http://dokku.viewdocs.io/dokku/
[DigitalOcean]: https://www.digitalocean.com/
[letsencrypt]: https://github.com/dokku/dokku-letsencrypt
[redis]: https://github.com/dokku/dokku-redis
[postgres]: https://github.com/dokku/dokku-postgres
[Let's Encrypt]: https://letsencrypt.org/
[deployable]: http://repo.or.cz/deployable.git
