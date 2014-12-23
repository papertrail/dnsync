# Ddnsync


## DESCRIPTION

Dnsync provides a simple way to replicate records from DNSimple to NSONE.

## INSTALLATION

    $ gem install dnsync



## Authentication

Authentication can be provided either by command line arguments, environment
variables, or environment variable files.

Environment variable files are files that contain a list of enviroment variable
name value pairs, like:

```
DNSYNC_DNSIMPLE_EMAIL=user@email.com
DNSYNC_DNSIMPLE_TOKEN=xxxxxxxxxx
```

The files are looked for in:

* `$HOME/dnsync.env`
* `<dnsync-code-root>/.env`
* `$PWD/.env`


### DNSimple

To authenticate against DNSimple, the command line arguments are:

```
        --dnsimple-email=EMAIL       DNSimple email address
        --dnsimple-token=TOKEN       DNSimple token
```

Alternately, the environment variables `DNSYNC_DNSIMPLE_EMAIL` and
`DNSYNC_DNSIMPLE_TOKEN` can be used.

### NSONE

To authenticate against NSONE, the command line arguments are:

```
        --nsone-token=TOKEN          NSOne token
```

## USING

### Getting a zone dump

To get a zone dump from DNSimple:

    $ dnsync --domain=domain.com dump dnsimple

To get a zone dump from NSONE:

    $ dnsync --domain=domain.com dump nsone



### Doing a one-time synchronization

To do a one-time synchronization:

    $ dnsync --domain=domain.com sync


### Monitoring a DNSimple zone for changes

To monitor a DNSimple domain for changes and automatically propagate the
changes to NSONE:

    $ dnsync --domain=domain.com monitor

