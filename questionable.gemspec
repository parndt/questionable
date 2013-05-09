# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "questionable"
  gem.version       = "0.0.1"
  gem.authors       = ["Philip Arndt"]
  gem.email         = ["parndt@gmail.com"]
  gem.description   = "Grabs some kinds of images from the websites that host them"
  gem.summary       = "Grabs some kinds of images from the websites that host them. Don't use on sites that disagree with this."
  gem.homepage      = "https://github.com/parndt/questionable"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
