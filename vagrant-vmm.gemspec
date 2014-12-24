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
  spec.description   = %q{This provider will allow you to create VMs in the remote Virtual Machine Manager.}
  spec.homepage      = "https://github.com/jarig/vagrant-vmm"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
