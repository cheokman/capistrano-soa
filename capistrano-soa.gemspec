# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano/version"

Gem::Specification.new do |s|

  s.name        = "capistrano-soa"
  s.version     =  "0.0.8"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Wu"]
  s.email       = ["wucheokman@gmail.com"]
  s.homepage    = "http://github.com/cheokman/capistrano-soa"
  s.summary     = %q{An extension for Capistrano supporting SOA Services Deployment}
  s.description = %q{Capistrano SOA let you management services group in SOA architecuture with multi-stage support.}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "README.md"
  ]
end
