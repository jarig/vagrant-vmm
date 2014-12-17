# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-vmm/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-vmm"
  spec.version       = VagrantPlugins::VMM::VERSION
  spec.authors       = ["jarig"]
  spec.email         = ["gjarik@gmail.com"]
  spec.summary       = %q{Plugin for running VMs via Virtual Machine Manager.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "https://github.com/jarig"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
