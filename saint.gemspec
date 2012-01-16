# -*- encoding: utf-8 -*-
require File.expand_path('../lib/saint/version', __FILE__)

Gem::Specification.new do |s|

  s.name = 'saint'
  s.version = Saint::VERSION
  s.authors = ['Silviu Rusu']
  s.email = ['slivuz@gmail.com']
  s.homepage = 'http://saintrb.org'
  s.summary = 'Simple Admin Interface'
  s.description = 'A simple backend to easily manage ORM models'

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency('presto', '>= 0.0.12')
  s.add_dependency('erubis')
  s.add_dependency('data_mapper', '>= 1.1.0')
  s.add_dependency('dm-is-tree', '>= 1.1.0')
  s.add_dependency('mini_magick', '>= 3.0')

  s.require_paths = ['lib']
  s.files = Dir['lib/**/*'] + Dir['*.md'] + %w[Rakefile Gemfile saint.gemspec]

end
