# frozen_string_literal: true

# require external dependencies
require 'pagy'
require 'pagy/toolbox/helpers/support/series'
require 'pagy/toolbox/helpers/support/a_lambda'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.ignore("#{__dir__}/generators")
  loader.setup
end

module SmartListing
  require_relative 'smart_listing/engine' if defined?(Rails)

  mattr_reader :configs

  @configs = {}

  def self.configure(profile = :default)
    yield @configs[profile] ||= SmartListing::Configuration.new
  end

  def self.config(profile = :default)
    @configs[profile] ||= SmartListing::Configuration.new
  end
end
