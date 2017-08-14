# ChromeRemote

ChromeRemote is a client implementation of the [Chrome DevTools Protocol][1] in Ruby. It lets you instrument, inspect, debug and profile instances of Chrome/Chromium based browsers from your Ruby code.

[1]: https://chromedevtools.github.io/devtools-protocol/

## Usage example

The following snippet navigates to `https://github.com`, dumps any request made while loading the page, and takes a screenshot once the page is loaded:

```ruby
require 'chrome_remote'
require 'base64'

chrome = ChromeRemote.client

# Enable events
chrome.send_cmd "Network.enable"
chrome.send_cmd "Page.enable"

# Setup handler to log network requests
chrome.on "Network.requestWillBeSent" do |params|
  puts params["request"]["url"]
end

# Navigate to github.com and wait for the page to load
chrome.send_cmd "Page.navigate", url: "https://github.com"
chrome.wait_for "Page.loadEventFired"

# Take page screenshot
response = chrome.send_cmd "Page.captureScreenshot"
File.write "screenshot.png", Base64.decode64(response["data"])
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'chrome_remote'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install chrome_remote
```

## Usage

To use ChromeRemote, you'll need a Chrome instance running on a known port (`localhost:9222` is the default), using the `--remote-debugging-port` flag.

In Linux:

```
$ google-chrome --remote-debugging-port=9222
```

In macOS:

```
$ /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
```

In Windows 7 or above:

```
> "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

#### Headless mode

Additionally, since version 59, you can use the `--headless` flag to start Chrome in [headless mode][2]

[2]: https://developers.google.com/web/updates/2017/04/headless-chrome

### Using the ChromeRemote API

The [Chrome DevTools Protocol][1] is divided into a number of domains ([Page][3], [DOM][4], [Debugger][5], [Network][6], etc.). Each domain defines a number of **commands** it supports and **events** it generates. 

ChromeRemote provides a simple API that lets you send commands, and handle events of any of the domains in the protocol.

To start with, you need an instance of the `ChromeRemote` class.

```ruby
chrome = ChromeRemote.client host: 'localhost', # optional, default: localhost
                          port: 9992         # optional, default: 9992
```

Now, to send commands, ChromeRemote provides the `ChromeRemote#send_cmd` method. For example, this is how you make Chrome navigate to a url by sending the [Page.navigate][7] command:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Page.navigate", url: "https://github.com"
# => {:frameId=>1234}
```

To tackle events, you have several options but, first of all, you need to enable events for any domain you're interested in. You only need to do this once per domain:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Network.enable"
```

Now, you can use the `ChromeRemote#on` method to subscribe to an event. For instance, this is how you subscribe to the [Network.requestWillBeSent][8] event:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Network.enable"

chrome.on "Network.requestWillBeSent" do |params|
  puts params["request"]["url"]
end
```
    
With the `ChromeRemote#wait_for` method, you can wait until the next time a given event is triggered. For example, the following snippet navigates to a page and waits for the [Page.loadEventFired][9] event to happen:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Page.navigate", url: "https://github.com"

chrome.wait_for "Page.loadEventFired"
# => {:timestamp=>34}
```

In certain occasions, after you have subscribed to one or several events, you may just want to process messages indefinitely, and let the event handlers process any event that may happen until you kill your script. For those cases, ChromeRemote provides the `ChromeRemote#listen` method:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Network.enable"

chrome.on "Network.requestWillBeSent" do |params|
  puts params["request"]["url"]
end

chrome.listen # will process incoming messages indefinitely
```

Finally, you have `ChromeRemote#listen_until` that will listen and process incoming messages but only until a certain condition is met. For instance, the following snippet waits until 5 requests are received and then continues:

```ruby
chrome = ChromeRemote.client
chrome.send_cmd "Network.enable"

requests = 0
chrome.on "Network.requestWillBeSent" do |params|
  requests += 1
end

chrome.listen_until { requests == 5 }

# do other stuff
```

[3]: https://chromedevtools.github.io/devtools-protocol/tot/Page/
[4]: https://chromedevtools.github.io/devtools-protocol/tot/DOM/
[5]: https://chromedevtools.github.io/devtools-protocol/tot/Debugger/
[6]: https://chromedevtools.github.io/devtools-protocol/tot/Network/
[7]: https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-navigate
[8]: https://chromedevtools.github.io/devtools-protocol/tot/Network/#event-requestWillBeSent
[9]: https://chromedevtools.github.io/devtools-protocol/tot/Page/#event-loadEventFired

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version (if you're a maintainer), update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cavalle/chrome_remote. 

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to follow the [code of conduct](https://github.com/cavalle/chrome_remote/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).