# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'braingasm/version'

Gem::Specification.new do |spec|
  spec.name          = "braingasm"
  spec.version       = Braingasm::VERSION
  spec.author        = "Daniel Rødskog"
  spec.email         = "danielmero@gmail.com"

  spec.summary       = %q{It's liek brainfuck and assembly in one!}
  spec.description   = %q{braingasm combines the readability of brainfuck with the high-level functionality of assembly}
  spec.homepage      = "https://github.com/daniero/braingasm"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 2.3'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "trollop", "~> 2.1.2"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 12"
  spec.add_development_dependency "rspec", "~> 3.6"
end
