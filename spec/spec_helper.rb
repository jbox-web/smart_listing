# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

# Start SimpleCov
SimpleCov.start do
  formatter SimpleCov::Formatter::JSONFormatter
  add_filter 'spec/'
end

# Load Rails dummy app
ENV['RAILS_ENV'] = 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)

# Load test gems
require 'rspec/rails'
require 'capybara/cuprite'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.expand_path('support/**/*.rb', __dir__)].each { |f| require f }

# Load our own config
require_relative 'config_capybara'
require_relative 'config_rspec'

module Test
  class UsersController < ApplicationController
    include SmartListing::Helper::ControllerExtensions

    helper  SmartListing::Helper

    attr_accessor :smart_listings

    def params
      { value: 'params' }
    end

    def cookies
      { value: 'cookies' }
    end

    def smart_listing_collection
      [1, 2]
    end
  end
end
