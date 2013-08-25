## Yet Another Rubygems Proxy

> Yarp is a small [Sinatra](http://www.sinatrarb.com) app that makes your
> [bundler](http://bundler.io) faster. You'll love it if you update your
> apps a lot... or simply deploy a lot.

On a example medium-sizes application with 34 direct gems dependencies, Yarp
makes my `bundle` commands up to 80% faster:


<table>
    <tr>
        <td></td>
        <td>direct Rubygems</td>
        <td>with `yarp.io`</td>
        <td>local Yarp</td>
    </tr>
    <tr>
        <td>bundle install (1 gem missing)</td>
        <td>170 s</td>
        <td>51 s</td>
        <td>24 s</td>
    </tr>
    <tr>
        <td>bundle update (73 updates)</td>
        <td>140 s</td>
        <td>65 s</td>
        <td>45 s</td>
    </tr>
    <tr>
        <td>bundle update (no change)</td>
        <td>26 s</td>
        <td>13 s</td>
        <td>8.5 s</td>
    </tr>
</table>

Thats a 45% percent win right there. 8 seconds shaved of my deploy times. If
you deploy 20 times a day to your staging environments and 5 times a day to
production, you're getting 15 minutes of your life back every week. Make
those count!


### Installation and usage

Deploy your own Yarp or use the one at `yarp.io`.

#### For projects using `bundler`

Just replace this line on top of your Gemfile:

    source 'http://rubygems.org'

By one of the following:

    source 'http://us.yarp.io'
    source 'http://eu.yarp.io'

You're done.


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
