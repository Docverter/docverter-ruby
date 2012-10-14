# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docverter/version'

Gem::Specification.new do |gem|
  gem.name          = "docverter"
  gem.version       = Docverter::VERSION
  gem.authors       = ["Pete Keen"]
  gem.email         = ["pete@docverter.com"]
  gem.description   = %q{API for converting documents with the Docverter service}
  gem.summary       = %q{API for converting documents with the Docverter service}
  gem.homepage      = "http://www.docverter.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("rest-client", ["~>1.6.7"])
  gem.add_development_dependency("mocha")
  gem.add_development_dependency("shoulda")
end
