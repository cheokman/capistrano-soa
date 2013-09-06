# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "capistrano/version"

Gem::Specification.new do |s|

  s.name        = "capistrano-soa"
  s.version     =  "0.0.5"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jamis Buck", "Lee Hambley"]
  s.email       = ["jamis@jamisbuck.org", "lee.hambley@gmail.com"]
  s.homepage    = "http://github.com/capistrano/capistrano"
  s.summary     = %q{Capistrano - Welcome to easy deployment with Ruby over SSH}
  s.description = %q{Capistrano is a utility and framework for executing commands in parallel on multiple remote machines, via SSH.}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "README.md"
  ]
end
