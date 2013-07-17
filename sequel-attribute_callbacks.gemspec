# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sequel-attribute_callbacks/version'

Gem::Specification.new do |gem|
  gem.name          = "sequel-attribute_callbacks"
  gem.version       = Sequel::AttributeCallbacks::VERSION
  gem.authors       = ["Rafał Rzepecki"]
  gem.email         = ["divided.mind@gmail.com"]
  gem.description   = %q{Model plugin making it easy to define callbacks on modification of specific attributes in the database}
  gem.summary       = %q{Attribute modification callbacks}
  gem.homepage      = "https://github.com/dividedmind/sequel-attribute_callbacks"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_runtime_dependency 'sequel', '~>3.44'
  
  gem.add_development_dependency 'rake', '~>10.0'
  gem.add_development_dependency 'rspec', '~>2.12'
  gem.add_development_dependency 'pg'
end
