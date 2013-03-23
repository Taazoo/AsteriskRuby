# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'bundler/version'

Gem::Specification.new do |s|
  s.name        = "AsteriskRuby"
  s.version     = Bundler::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Mitch Rodrigues"]
  s.email       = ["mitch@taazoo.net"]
  s.homepage    = "http://github.com/Taazoo/AsteriskRuby"
  s.summary     = "Agi"
  s.description = "Bundler manages an application's dependencies through its entire life, across many machines, systematically and repeatably"
  s.files        = Dir.glob("{bin,lib}/**/*")
  s.require_path = 'lib'
end