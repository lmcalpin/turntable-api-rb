# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "turntable_api/version"

Gem::Specification.new do |s|
  s.name        = "turntable_api"
  s.version     = TurntableAPI::VERSION
  s.authors     = ["Lawrence Mcalpin"]
  s.email       = ["lmcalpin+turntable_api@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{API for creating Turntable bots.}
  s.description = %q{A simple API for making Turntable.fm bots.}
  s.rubyforge_project = "turntable_api"
  s.add_dependency "websocker"
end
