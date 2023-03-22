# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cred_stash/version'

Gem::Specification.new do |spec|
  spec.name          = "rcredstash"
  spec.version       = CredStash::VERSION
  spec.authors       = ["adorechic"]
  spec.email         = ["adorechic@gmail.com"]
  spec.homepage      = 'https://github.com/adorechic/rcredstash'

  spec.summary       = %q{A Ruby port of CredStash}
  spec.description   = %q{A Ruby port of CredStash}
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk-kms'
  spec.add_dependency 'aws-sdk-dynamodb'
  spec.add_dependency 'thor'

  spec.add_development_dependency "bundler", "~> 2.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
