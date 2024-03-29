# frozen_string_literal: true

require_relative 'lib/smart_listing/version'

Gem::Specification.new do |s|
  s.name        = 'smart_listing'
  s.version     = SmartListing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sology']
  s.email       = ['contact@sology.eu']
  s.homepage    = 'https://github.com/Sology/smart_listing'
  s.description = 'Ruby on Rails data listing gem with built-in sorting, filtering and in-place editing.'
  s.summary     = 'SmartListing helps creating sortable lists of ActiveRecord collections with pagination, filtering and inline editing.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency 'kaminari', '>= 0.17'
  s.add_runtime_dependency 'rails', '>= 6.1'

  s.add_development_dependency 'appraisal'
  s.add_development_dependency 'bootstrap-sass'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'cuprite'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'jquery-rails'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rspec-retry'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-capybara'
  s.add_development_dependency 'rubocop-rake'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3', '~> 1.4.0'

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1.0")
    s.add_development_dependency 'net-imap'
    s.add_development_dependency 'net-pop'
    s.add_development_dependency 'net-smtp'
  end
end
