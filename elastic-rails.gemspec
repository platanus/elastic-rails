# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic/version'

Gem::Specification.new do |spec|
  spec.name          = "elastic-rails"
  spec.version       = Elastic::VERSION
  spec.authors       = ["Ignacio Baixas"]
  spec.email         = ["ignacio@platan.us"]

  spec.summary       = %q{Elasticsearch integration for Ruby on Rails by Platanus}
  spec.description   = %q{Elasticsearch integration for Ruby on Rails by Platanus}
  spec.homepage      = "https://github.com/surbtc/elastic-rails"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "elasticsearch", "~> 6.8"
  spec.add_dependency "activesupport", [">= 4.0", "< 8.0"]

  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rspec-nc", "~> 0.2"
  spec.add_development_dependency "guard", "~> 2.11"
  spec.add_development_dependency "guard-rspec", "~> 4.5"
  spec.add_development_dependency "terminal-notifier-guard", "~> 1.6", ">= 1.6.1"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "pry-nav", "~> 0.3.0"
end
