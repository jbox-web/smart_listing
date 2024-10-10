# frozen_string_literal: true

module SmartListing
  module ApplicationHelper
    include Pagy::Frontend

    module ControllerExtensions
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
    end

    def smart_listing_config_profile
      defined?(super) ? super : :default
    end


    def smart_listing_render(name = controller_name, *args)
      options = args.dup.extract_options!
      smart_listing_for(name, *args) do |smart_listing|
        concat(smart_listing.render_list(options[:locals]))
      end
    end


    def smart_listing_config
      SmartListing.config(smart_listing_config_profile)
    end


    # Updates smart listing
    #
    # Posible calls:
    # smart_listing_update name, options = {}
    # smart_listing_update options = {}
    def smart_listing_update(*args)
      options = args.extract_options!
      name = (args[0] || options[:name] || controller_name).to_sym
      smart_listing = @smart_listings[name]

      # don't update list if params are missing (prevents interfering with other lists)
      if params.keys.select { |k| k.include?('smart_listing') }.present? && !params[smart_listing.base_param]
        return unless options[:force] # rubocop:disable Style/SoleNestedConditional
      end

      builder = SmartListing::Builder.new(name, smart_listing, self, {}, nil)
      render(
        partial: 'smart_listing/update_list',
        locals: {
          name: smart_listing.name,
          part: smart_listing.partial,
          smart_listing: builder,
          smart_listing_data: {
            smart_listing_config.data_attributes(:params) => smart_listing.all_params,
            smart_listing_config.data_attributes(:max_count) => smart_listing.max_count,
            smart_listing_config.data_attributes(:item_count) => smart_listing.count
          },
          locals: options[:locals] || {}
        }
      )
    end


    def pagy_url_for(pagy, page, absolute: false)
      list = pagy.vars[:params][:type]
      url_params = params.to_unsafe_h.merge(pagy.vars[:params]).merge(pagy.vars[:page_param] => page)
      url_params[:"#{list}_list_smart_listing"] ||= {}
      url_params[:"#{list}_list_smart_listing"][pagy.vars[:page_param]] = page

      url_for(url_params)
    end


    private


      # Outputs smart list container
      # rubocop:disable Style/IfUnlessModifier
      def smart_listing_for(name, *args, &block)
        raise ArgumentError, 'Missing block' unless block

        name = name.to_sym
        options = args.extract_options!
        bare = options.delete(:bare)

        builder = SmartListing::Builder.new(name, @smart_listings[name], self, options, block)

        data = {}
        data[smart_listing_config.data_attributes(:max_count)]     = @smart_listings[name].max_count if @smart_listings[name].max_count && @smart_listings[name].max_count > 0
        data[smart_listing_config.data_attributes(:item_count)]    = @smart_listings[name].count
        data[smart_listing_config.data_attributes(:href)]          = @smart_listings[name].href if @smart_listings[name].href
        data[smart_listing_config.data_attributes(:callback_href)] = @smart_listings[name].callback_href if @smart_listings[name].callback_href
        data.merge!(options[:data]) if options[:data]

        if bare
          capture(builder, &block)
        else
          content_tag(:div, class: smart_listing_config.classes(:main), id: name, data: data) do
            concat(content_tag(:div, '', class: smart_listing_config.classes(:loading)))
            concat(content_tag(:div, class: smart_listing_config.classes(:content)) do
              concat(capture(builder, &block))
            end)
          end
        end
      end
      # rubocop:enable Style/IfUnlessModifier

  end
end
