# frozen_string_literal: true

# require external dependencies
require 'kaminari'

# require internal dependencies
require_relative 'smart_listing/engine'
require_relative 'smart_listing/base'
require_relative 'smart_listing/config'
require_relative 'smart_listing/version'

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

end
