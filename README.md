# Dnsync

Dnsync provides a simple way to replicate records from [DNSimple] to [NSONE][NSONE]
(because [DNSimple] used to not support [AXFR] for zone transfer). For a domain
owner, using two different DNS networks is much better DDoS protection than
relying on any single one.


## Installation

    $ gem install dnsync

or to install a prerelease, add to your `Gemfile`:

    gem 'dnsync', :git => 'git://github.com/papertrail/dnsync.git'

and use:

    $ bundle exec dnsync

## Using

Dnsync can be used to either do one-time synchronization or run in the
foreground forever, synchronizing every 10 seconds.


### Doing a one-time synchronization

To do a one-time synchronization:

    $ dnsync <options> sync


### Monitoring a DNSimple zone for changes

To monitor a DNSimple domain for changes and automatically propagate the
changes to NSONE:

    $ dnsync <options> monitor


## Configuration

Configuration and authentication can be provided either by command line
arguments, environment variables, or environment variable files.

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


### General options

To specify the domain to synchronize, the command line argument is:

```
        --domain=DOMAIN              Domain to synchronize
```

Alternatively, the environment variable `DNSYNC_DOMAIN` can be used.

### Monitor options

The `monitor` command has a few options to help configure how it behaves:

```
        --monitor-frequency=FREQUENCY
                                     Frequency to check DNSimple for updates
        --status-port=PORT           Port to run status HTTP server on

```

These arguments can also be specified as environment variables:
`DNSYNC_MONITOR_FREQUENCY` and `DNSYNC_STATUS_PORT`.


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
        --nsone-token=TOKEN          NSONE token
```

Alternatively, the environment variable `DNSYNC_NSONE_TOKEN` is used.


## Running on Heroku

Heroku provides a simple place to run synchronization.

To get up and running with very little effort, click the button:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/papertrail/dnsync-heroku)

To get the synchronizer up and running by hand:

### 1. Create a new directory for the heroku app:

    $ mkdir dns-synchronizer
    $ cd dns-synchronizer
    $ git init
    $ touch .gitignore
    $ git add .gitignore
    $ git commit -m 'Initial commit'

### 2. Create a basic ruby project:

    $ bundle init
    $ echo "gem 'dnsync'" >> Gemfile
    $ bundle

### 3. Create a `Procfile` to run the worker:

    $ echo 'web: bundle exec dnsync --status-port=$PORT monitor' >> Procfile

### 4. Commit the changes:

    $ git add Gemfile Gemfile.lock Procfile
    $ git commit -m 'Setting up dnsync'

### 5. Create a heroku app:

    $ heroku apps:create

### 6. Deploy to heroku:

    $ git push heroku master

### 7. Set configuration variables:

    $ heroku config:set DNSYNC_DNSIMPLE_EMAIL=user@domain.com DNSYNC_DNSIMPLE_TOKEN=xxxx \
        DNSYNC_NSONE_TOKEN=xxxx DNSYNC_DOMAIN=domain.com

### 8. Setting up monitoring

Now that the service is running and synchronizing, it would be wise to
monitor of the service.

As always, it's good to keep an eye on your logs, so use `heroku logs -t` or
[send the logs](http://help.papertrailapp.com/kb/hosting-services/heroku/) to
[Papertrail](https://papertrailapp.com/).

To ensure that the synchronization is working properly, poll the status URL
with your favorite website monitor.

Poll `https://<your-app>.herokuapp.com/status` for a 200 response code.

If it responds with a non-200 error code, it will return the reason for the
monitoring failure.


## Debugging

### Getting a zone dump

To get a zone dump from DNSimple:

    $ dnsync --domain=domain.com dump dnsimple

To get a zone dump from NSONE:

    $ dnsync --domain=domain.com dump nsone


[DNSimple]: https://dnsimple.com/
[NSONE]: https://nsone.net/
[AXFR]: http://cr.yp.to/djbdns/axfr-notes.html
