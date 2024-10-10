# frozen_string_literal: true

# require external dependencies
require 'kaminari'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.ignore("#{__dir__}/generators")
  loader.setup
end

# Fix parsing nested params
module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for @params.deep_merge(page_param(page)).merge(only_path: true)
      end

      private

      def page_param(page)
        Rack::Utils.parse_nested_query("#{@param_name}=#{page <= 1 ? nil : page}").symbolize_keys
      end
    end
  end
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
