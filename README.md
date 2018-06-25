# Get Me Started, Fast!

There's a one-step procedure if you are fine with unattended installation
and e.g. want to set domain `example.com`:

1. Spin up a new VPS somewhere, e.g. [Digital Ocean][]:
    - choose the latest Debian release
    - select the smallest size if you just want to give it a try
    - set up your SSH keys
    - use the following `cloud-init` file:

            #!/bin/sh
            apt-get update &&
            apt-get install -y curl perl &&
            curl -LO https://github.com/polettix/dokku-boot/raw/master/dokku-boot.pl &&
            UNATTENDED=yes DOMAIN=example.com perl dokku-boot.pl

    - take note of the IP address and put it into environment variable
      `DOKKU_IP`

There you go, your personal PaaS is waiting for you at `$DOKKU_IP`!

# What now?

We will suppose that your VPS has FQDN `foobar.example.com` (which you
somehow set in the DNS).

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

    To dokku@foobar.example.com:sample-mojo
    * [new branch]      master -> master
    Branch master set up to track remote branch master from dokku.

    # Now enjoy your new application, use URL provided after line
    #
    # =====> Application deployed:
    #
    # above
    $ curl http://sample-mojo.foobar.example.com
    Hello, World!

# Shameless Plug

If you happen to use [Digital Ocean][] and also [ClouDNS][] customer, there's
even a quicker route to spin up machines at will. Note that these two services
are not for free, although you can spend less than about 5$ to get started (or
less, depending on what you already have).

There's some one-time setup to be done:

1. subscribe to [Digital Ocean][] and generate an API access token ([see the
   FAQ][do-api-faq]). You can use [my referral link][do-referral] to get
   started with $10 credit (as of November 2016 at least).
   
2. define at least one SSH Key in [Digital Ocean][], [read here][do-ssh-keys]
   if you don't know how to do it;

3. subscribe to [ClouDNS][] and generate API credentials (this requires at
   least [premium][cloudns-premium] level, again you're welcome to use [my
   referral link][cloudns-referral]). To generate the API credentials you can
   [read this article][cloudns-api-help];

4. set up management of a domain in [ClouDNS][], we will assume it's
   `paas.example.com`. They usually have a [promotions][cloudns-promotions]
   page where you can get a domain for as low as about $3, but if you already
   have something (e.g. a delegation from a friend) it's OK too;

5. put the relevant credentials in file `env.sh` (in your *current* directory,
   whatever it is). I find it useful to create "sub-users" and restrict the
   amount of freedom these API users have. Example (substitute where you see
   fit):

        : ${DO_TOKEN:='YOUR-DIGITAL-OCEAN-TOKEN'}
        : ${DO_SSH_KEY_ID:='YOUR-DIGITAL-OCEAN-SSH-KEY-ID'}
        : ${CLOUDNS_AUTH:='sub-auth-user=CLOUDNS-SUB-USER&auth-password=CLOUDNS-SUB-PASS'}
        : ${VM_PROVIDER:='digital-ocean'}
        : ${DNS_PROVIDER:='cloudns'}
        export DO_TOKEN DO_SSH_KEY_ID CLOUDNS_AUTH VM_PROVIDER DNS_PROVIDE

Preparation phase is over, now you're read to spin up as many VMs as you see
fit.

    shell$ /path/to/dokku-boomote.sh paas.example.com
    # ... 6-7 minutes and a few logs later you read this:
    *.paas.example.com => W.X.Y.Z

If you plan to have multiple machines, you can of course use sub-domains for
creating the wildcards, like this:

    shell$ /path/to/dokku-boomote.sh env1.paas.example.com
    # ...
    *.env1.paas.example.com => A.B.C.D

    shell$ /path/to/dokku-boomote.sh env2.paas.example.com
    # ...
    *.env2.paas.example.com => A.B.C.D

and so on. Sky (well, your wallet actually) is the limit!

# I'm Ready For Some Details Now!

Do you know [Dokku][]? They dub it as *The smallest PaaS implementation
you've ever seen*, and well... it really is.

It's easy to install. But but... this only gets you started. I wanted
something that:

- would be easy to run in a newly spawned VPS (e.g. in [Digital Ocean][])
- would also care to set up reasonable firewalling rules:
    - leave only ports `22`, `80` and `443` open
    - put sane restrictions on forwarding and output
- last, would install a few plugins I want to have around:
    - [letsencrypt][] to automate handling of *real* TLS certificates from
      [Let's Encrypt][]
    - [redis][]
    - [postgres][]

This is what `dokku-boot` is about.

If you want to customize it, you can modify/add scripts inside directory
`dokku-boot.d`. To regenerate the perl script that does the magic, you
will have to install [deployable][] and run `make`.


[Dokku]: http://dokku.viewdocs.io/dokku/
[Digital Ocean]: https://www.digitalocean.com/
[letsencrypt]: https://github.com/dokku/dokku-letsencrypt
[redis]: https://github.com/dokku/dokku-redis
[postgres]: https://github.com/dokku/dokku-postgres
[Let's Encrypt]: https://letsencrypt.org/
[deployable]: http://repo.or.cz/deployable.git
[ClouDNS]: https://www.cloudns.net/
[do-api-faq]: https://www.digitalocean.com/help/api/
[do-referral]: https://m.do.co/c/56e1ceafe14a
[cloudns-premium]: https://www.cloudns.net/premium/
[cloudns-referral]: http://www.cloudns.net/aff/id/84226/
[cloudns-api-help]: https://www.cloudns.net/wiki/article/42/
[do-ssh-keys]: https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2
[cloudns-promotions]: https://www.cloudns.net/domain-pricing-list/category/promotions/
