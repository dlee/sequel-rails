# -*- encoding: utf-8 -*-

require File.expand_path('../lib/sequel/rails/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "mcmire-sequel-rails"
  s.version     = Sequel::Rails.version
  s.authors     = ["Brasten Sager (brasten)", "Jonathan TRON", "Elliot Winkler"]
  s.email       = ["brasten@gmail.com", "jonathan.tron@thetalentbox.com", "elliot.winkler@gmail.com"]
  s.homepage    = "https://github.com/mcmire/sequel-rails"
  s.description = "Ruby gem for integrating Sequel with your Rails 3 app"
  s.summary     = "Ruby gem for integrating Sequel with your Rails 3 app"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency("sequel", ["~> 3.28"])
end
