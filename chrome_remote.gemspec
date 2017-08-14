# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chrome_remote/version"

Gem::Specification.new do |spec|
  spec.name          = "chrome_remote"
  spec.version       = ChromeRemote::VERSION
  spec.authors       = ["Luismi Cavalle"]
  spec.email         = ["luismi@lmcavalle.com"]

  spec.summary       = "ChromeRemote is a client implementation of the Chrome DevTools Protocol in Ruby"
  spec.homepage      = "https://github.com/cavalle/chrome_remote"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "websocket-driver", "~> 0.6"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "em-websocket", "~> 0.5"
  spec.add_development_dependency "byebug"
end
