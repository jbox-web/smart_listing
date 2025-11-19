# frozen_string_literal: true

module SmartListing
  module ControllerHelper

    # Creates new smart listing
    #
    # Possible calls:
    # smart_listing_create name, collection, options = {}
    # smart_listing_create options = {}
    def smart_listing_create(*args)
      options = args.extract_options!
      name = (args[0] || options[:name] || controller_name).to_sym
      collection = args[1] || options[:collection] || smart_listing_collection

      view_context = respond_to?(:controller) ? controller.view_context : self.view_context
      options = { config_profile: view_context.smart_listing_config_profile }.merge(options)

      list = SmartListing::Base.new(name, collection, options)
      list.setup(params, cookies)

      @smart_listings ||= {}
      @smart_listings[name] = list

      list.collection
    end

    def smart_listing(name)
      @smart_listings[name.to_sym]
    end

    def _prefixes
      super << 'smart_listing'
    end
  end
end
