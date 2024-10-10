# frozen_string_literal: true

module SmartListing
  class Builder

    class_attribute :smart_listing_helpers

    def initialize(smart_listing_name, smart_listing, template, options)
      @smart_listing_name = smart_listing_name
      @smart_listing = smart_listing
      @template = template
      @options = options
    end

    def name
      @smart_listing_name
    end

    def paginate(_options = {})
      return unless @smart_listing.pagy_collection.series.size > 1

      render(partial: @smart_listing.pagy_options[:partial], locals: { pagy: @smart_listing.pagy_collection, remote: @smart_listing.remote? }).html_safe
    end

    def collection
      @smart_listing.collection
    end

    # Check if smart list is empty
    def empty?
      @smart_listing.count == 0
    end

    def pagination_per_page_links(_options = {})
      container_classes = [@template.smart_listing_config.classes(:pagination_per_page)]
      container_classes << @template.smart_listing_config.classes(:hidden) if empty?

      per_page_sizes = @smart_listing.page_sizes.clone
      per_page_sizes.push(0) if @smart_listing.unlimited_per_page?

      locals = {
        container_classes: container_classes,
        per_page_sizes: per_page_sizes
      }

      @template.render(partial: 'smart_listing/pagination_per_page_links', locals: default_locals.merge(locals))
    end

    # rubocop:disable Style/IfUnlessModifier
    def pagination_per_page_link(page)
      if @smart_listing.per_page.to_i != page
        url = @template.url_for(@smart_listing.params.merge(@smart_listing.all_params(per_page: page, page: 1)))
      end

      locals = {
        page: page,
        url: url
      }

      @template.render(partial: 'smart_listing/pagination_per_page_link', locals: default_locals.merge(locals))
    end
    # rubocop:enable Style/IfUnlessModifier

    def sortable(title, attribute, options = {})
      dirs = options[:sort_dirs] || @smart_listing.sort_dirs || [nil, 'asc', 'desc']

      next_index = dirs.index(@smart_listing.sort_order(attribute)).nil? ? 0 : (dirs.index(@smart_listing.sort_order(attribute)) + 1) % dirs.length

      sort_params = {
        attribute => dirs[next_index]
      }

      locals = {
        order: @smart_listing.sort_order(attribute),
        url: @template.url_for(@smart_listing.params.merge(@smart_listing.all_params(sort: sort_params))),
        container_classes: [@template.smart_listing_config.classes(:sortable)],
        attribute: attribute,
        title: title,
        remote: @smart_listing.remote?
      }

      @template.render(partial: 'smart_listing/sortable', locals: default_locals.merge(locals))
    end

    def update(options = {})
      part = options.delete(:partial) || @smart_listing.partial || @smart_listing_name

      @template.render(partial: 'smart_listing/update_list', locals: { name: @smart_listing_name, part: part, smart_listing: self })
    end

    # Renders the main partial (whole list)
    def render_list(locals = {})
      return unless @smart_listing.partial

      @template.render partial: @smart_listing.partial, locals: { smart_listing: self }.merge(locals || {})
    end

    # Basic render block wrapper that adds smart_listing reference to local variables
    def render(options = {}, locals = {}, &block)
      if locals.empty?
        options[:locals] ||= {}
        options[:locals][:smart_listing] = self
      else
        locals[:smart_listing] = self
      end

      @template.render options, locals, &block
    end

    # Add new item button & placeholder to list
    def item_new(options = {}, &block)
      no_records_classes = [@template.smart_listing_config.classes(:no_records)]
      no_records_classes << @template.smart_listing_config.classes(:hidden) unless empty?
      new_item_button_classes = []
      new_item_button_classes << @template.smart_listing_config.classes(:hidden) if max_count?

      locals = {
        colspan: options.delete(:colspan),
        no_items_classes: no_records_classes,
        no_items_text: options.delete(:no_items_text) || @template.t('smart_listing.msgs.no_items'),
        new_item_button_url: options.delete(:link),
        new_item_button_classes: new_item_button_classes,
        new_item_button_text: options.delete(:text) || @template.t('smart_listing.actions.new'),
        new_item_autoshow: block.present?,
        new_item_content: nil
      }

      if block
        locals[:placeholder_classes] = [@template.smart_listing_config.classes(:new_item_placeholder)]
        locals[:placeholder_classes] << @template.smart_listing_config.classes(:hidden) if !empty? && max_count?
        locals[:new_item_action_classes] = [@template.smart_listing_config.classes(:new_item_action), @template.smart_listing_config.classes(:hidden)]

        locals[:new_item_content] = @template.capture(&block)
      else
        locals[:placeholder_classes] = [@template.smart_listing_config.classes(:new_item_placeholder), @template.smart_listing_config.classes(:hidden)]
        locals[:new_item_action_classes] = [@template.smart_listing_config.classes(:new_item_action)]
        locals[:new_item_action_classes] << @template.smart_listing_config.classes(:hidden) if !empty? && max_count?
      end

      @template.render(partial: 'smart_listing/item_new', locals: default_locals.merge(locals))
    end

    def count
      @smart_listing.count
    end

    # Check if smart list reached its item max count
    def max_count?
      return false if @smart_listing.max_count.nil?

      @smart_listing.count >= @smart_listing.max_count
    end

    private

    def default_locals
      { smart_listing: @smart_listing, builder: self }
    end
  end
end
