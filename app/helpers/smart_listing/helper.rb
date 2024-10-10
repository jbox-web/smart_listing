# frozen_string_literal: true

module SmartListing
  module Helper
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

      def smart_listing(name)
        @smart_listings[name.to_sym]
      end

      def _prefixes
        super << 'smart_listing'
      end
    end

    def smart_listing_config_profile
      defined?(super) ? super : :default
    end

    def smart_listing_config
      SmartListing.config(smart_listing_config_profile)
    end

    # Outputs smart list container
    # rubocop:disable Layout/LineLength
    def smart_listing_for(name, *args, &block)
      raise ArgumentError, 'Missing block' unless block

      name = name.to_sym
      options = args.extract_options!
      bare = options.delete(:bare)

      builder = SmartListing::Builder.new(name, @smart_listings[name], self, options)

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
    # rubocop:enable Layout/LineLength

    def smart_listing_render(name = controller_name, *args)
      options = args.dup.extract_options!
      smart_listing_for(name, *args) do |smart_listing|
        concat(smart_listing.render_list(options[:locals]))
      end
    end

    # rubocop:disable Layout/LineLength
    def smart_listing_controls_for(name, *args, &block)
      smart_listing = @smart_listings.try(:[], name)

      classes = [smart_listing_config.classes(:controls), args.first.try(:[], :class)]

      form_tag(smart_listing.try(:href) || {}, remote: smart_listing.try(:remote?) || true, method: :get, class: classes, data: { smart_listing_config.data_attributes(:main) => name }) do
        concat(content_tag(:div, style: 'margin:0;padding:0;display:inline') do
          concat(hidden_field_tag("#{smart_listing.try(:base_param)}[_]", 1, id: nil)) # this forces smart_listing_update to refresh the list
        end)
        concat(capture(&block))
      end
    end
    # rubocop:enable Layout/LineLength

    # Render item action buttons (ie. edit, destroy and custom ones)
    def smart_listing_item_actions(actions = [])
      content_tag(:span) do
        actions.each do |action|
          next unless action.is_a?(Hash)

          locals = {
            action_if: action.key?(:if) ? action[:if] : true,
            url: action.delete(:url),
            icon: action.delete(:icon),
            title: action.delete(:title)
          }

          template = nil
          action_name = action[:name].to_sym

          case action_name
          when :show
            locals[:icon] ||= smart_listing_config.classes(:icon_show)
            template = 'action_show'
          when :edit
            locals[:icon] ||= smart_listing_config.classes(:icon_edit)
            template = 'action_edit'
          when :destroy
            locals[:icon] ||= smart_listing_config.classes(:icon_trash)
            locals[:confirmation] = action.delete(:confirmation)
            template = 'action_delete'
          when :custom
            locals[:html_options] = action
            template = 'action_custom'
          end

          locals[:icon] = [locals[:icon], smart_listing_config.classes(:muted)] unless locals[:action_if]

          if template
            concat(render(partial: "smart_listing/#{template}", locals: locals))
          else
            concat(render(partial: "smart_listing/action_#{action_name}", locals: { action: action }))
          end
        end
      end
    end

    def smart_listing_limit_left(name)
      name = name.to_sym
      smart_listing = @smart_listings[name]

      smart_listing.max_count - smart_listing.count
    end

    def pagy_url_for(pagy, page, absolute: false) # rubocop:disable Lint/UnusedMethodArgument
      list = pagy.vars[:params][:smart_listing_name]
      url_params = params.to_unsafe_h.merge(pagy.vars[:params])
      url_params[:"#{list}_smart_listing"] ||= {}
      url_params[:"#{list}_smart_listing"][pagy.vars[:page_param]] = page
      url_for(url_params)
    end

    #################################################################################################
    # JS helpers:

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

      builder = SmartListing::Builder.new(name, smart_listing, self, {})
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

    # Renders single item (i.e for create, update actions)
    #
    # Possible calls:
    # smart_listing_item name, item_action, object = nil, partial = nil, options = {}
    # smart_listing_item item_action, object = nil, partial = nil, options = {}
    # rubocop:disable Layout/LineLength
    def smart_listing_item(*args)
      options = args.extract_options!
      if %i[create create_continue destroy edit new remove update].include?(args[1])
        name = args[0]
        item_action = args[1]
        object = args[2]
        partial = args[3]
      else
        name = (options[:name] || controller_name).to_sym
        item_action = args[0]
        object = args[1]
        partial = args[2]
      end
      id = options[:id] || object.try(:id)
      valid = options[:valid] if options.key?(:valid)
      object_key = options.delete(:object_key) || :object
      new = options.delete(:new)

      render(partial: "smart_listing/item/#{item_action}", locals: { name: name, id: id, valid: valid, object_key: object_key, object: object, part: partial, new: new })
    end
    # rubocop:enable Layout/LineLength
  end
end
