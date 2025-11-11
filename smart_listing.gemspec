# frozen_string_literal: true

require_relative 'lib/smart_listing/version'

Gem::Specification.new do |s|
  s.name        = 'smart_listing'
  s.version     = SmartListing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sology']
  s.email       = ['contact@sology.eu']
  s.homepage    = 'https://github.com/Sology/smart_listing'
  s.summary     = 'SmartListing helps creating sortable lists of ActiveRecord collections with pagination, filtering and inline editing.'
  s.description = 'Ruby on Rails data listing gem with built-in sorting, filtering and in-place editing.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.2.0'

  s.files = Dir['README.md', 'Changed.md', 'LICENSE', 'lib/**/*.rb', 'config/**/*.yml', 'app/**/*.rb', 'app/**/*.erb']

  s.add_dependency 'pagy', '~> 9.4.0'
  s.add_dependency 'rails', '>= 7.0'
  s.add_dependency 'zeitwerk'
end
