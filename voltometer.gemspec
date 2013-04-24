# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'voltometer/version'

Gem::Specification.new do |gem|
  gem.name          = "voltometer"
  gem.version       = Voltometer::VERSION
  gem.authors       = ["lyon"]
  gem.email         = ["lyondhill@gmail.com"]
  gem.description   = %q{Voltage monitoring device for Voltrak}
  gem.summary       = %q{Voltage will be monitored form a dataTaker device and inserted into a mongodb database}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'moped'
  gem.add_dependency 'listen', '0.5.3'
  gem.add_dependency 'rb-inotify'
end
