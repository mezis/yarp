
	!! README IS WORK IN PROGRESS !!

## Yet Another Rubygems Proxy

> Yarp is a small [Sinatra](http://www.sinatrarb.com) app that makes your
> [bundler](http://bundler.io) faster. You'll love it if you update your
> apps a lot... or simply deploy a lot.

## Performance

Given gemfile

```
+   $ cat Gemfile
#source "http://localhost:9292"
source "https://rubygems.org"

gem "nanoc"
gem "pry"
gem "rack"
gem "rspec"
```

Running against rubygems:

```
$ bundle install --path .bundle/vendor --jobs 1
...
Bundle complete! 4 Gemfile dependencies, 42 gems now installed.
Bundled gems are installed into `./.bundle/vendor`

real    0m14.263s
user    0m4.648s
sys     0m0.856s

Running with cleaned caches:

```
$ bundle install --path .bundle/vendor --jobs 1
...
Bundle complete! 4 Gemfile dependencies, 42 gems now installed.
Bundled gems are installed into `./.bundle/vendor`

real    0m16.803s
user    0m3.876s
sys     0m0.664s
```

And after it was all cached:

```
$ bundle install --path .bundle/vendor --jobs 1
...
Bundle complete! 4 Gemfile dependencies, 42 gems now installed.
Bundled gems are installed into `./.bundle/vendor`

real    0m5.329s
user    0m4.498s
sys     0m0.809s
```

So it can get significantly faster after things were cached.

### Installation and usage

Deploy your own Yarp or use the one at `yarp.io`.

#### For projects using `bundler`

Just replace this line on top of your Gemfile:

    source 'http://rubygems.org'

By one of the following:

    source 'http://us.yarp.io'
    source 'http://eu.yarp.io'

You're done.

If you want/need SSL connections, you can use the Heroku URLs:

    source 'https://yarp-us.herokuapp.com'
    source 'https://yarp-eu.herokuapp.com'


#### Your own local Yarp

You can make this even faster by deploying your very own, local Yarp.
Example install with the excellent [Pow](http://pow.cx):

    curl get.pow.cx | sh      # unless you already have Pow
    git clone https://github.com/mezis/yarp.git ~/.yarp
    ln -s ~/.yarp ~/.pow/yarp

Then change your `Gemfile`'s' source line to:

    source ENV.fetch('GEM_SOURCE', 'http://eu.yarp.io')

And add the GEM_SOURCE to your `~/.profile` or `~/.zshrc`:

    export GEM_SOURCE=http://yarp.dev

Why the dance with `ENV.fetch`? Simply because your codebase may be deployed
or used somewhere lacking `yarp.dev`; this gives you a fallback to another
source of gems.


#### Outside of `bundler`

Edit the sources entry in your `~/.gemrc`:

    ---
    :sources:
    - http://yarp.dev

assuming you've followed the Pow instructions above; or use one of the
`yarp.io` servers instead.


### How it works & Caveats

Yarp caches calls to Rubygem's dependency API, spec files, and gems for 24
hours if using `(eu|us).yarp.io`. It redirects all other calls to Rubygems
directly.

This means that when gems get released or updated, you'll **lag a day
behind**.


### Hacking Yarp

Checkout, make sure you have a [Memcache](http://memcached.org/) running,
configure `.env`, and

    $ bundle exec foreman run rackup

Thake a long look at the [`.env`](.env) file, as most
configuration options for Yarp are there.


### License

Yarp is released under the MIT licence.
Copyright (c) 2013 HouseTrip Ltd.
