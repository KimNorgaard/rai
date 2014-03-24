# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rai/version"

Gem::Specification.new do |s|
  s.name                      = 'rai'
  s.version                   = Rai::VERSION
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors                   = ["Kim Nørgaard"]
  s.description               = 'Ruby-port of Adaptive Images (http://adaptive-images.com/)'
  s.summary                   = 'Scales images according to screen width'
  s.email                     = 'jasen@jasen.dk'
  s.homepage                  = %q{https://github.com/KimNorgaard/rai}
  s.licenses                  = 'Creative Commons Attribution 3.0 Unported License'

  s.add_runtime_dependency 'sinatra'
  s.add_runtime_dependency 'mini_magick'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end
