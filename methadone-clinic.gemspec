# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "methadone/version"

Gem::Specification.new do |s|
  s.name        = "methadone-clinic"
  s.version     = Methadone::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["davetron5000","dennisjbell"]
  s.email       = ["davetron5000 at gmail.com","dennis.j.bell at gmail.com"]
  s.homepage    = "http://github.com/dennisjbell/methadone-clinic"
  s.summary     = %q{Kick the bash habit and start your command-line apps off right}
  s.description = %q{Improvement to Methadone [http://github.com/davetron5000/methadone] that adds subcommands, option interaction rules (requires/excludes), and improved argument handling, while continuing to provide a lot of small but useful features for developing a command-line app, including an opinionated bootstrapping process, some helpful cucumber steps, and some classes to bridge logging and output into a simple, unified, interface that was in Methadone 1.3}
  s.rubyforge_project = "methadone-clinic"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency("bundler")
  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc","~> 3.9")
  s.add_development_dependency("cucumber")
  s.add_development_dependency("aruba")
  s.add_development_dependency("simplecov", "~> 0.5")
  s.add_development_dependency("clean_test")
  s.add_development_dependency("mocha", "0.13.2")
  s.add_development_dependency("sdoc")
  s.add_development_dependency("pry")
  s.add_development_dependency("rspec", "~> 3")
  s.add_development_dependency("i18n", "= 0.6.1")
end
