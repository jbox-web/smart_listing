# frozen_string_literal: true

module SmartListing
  class Builder

    def initialize(smart_listing_name, smart_listing, template, options, proc)
      @smart_listing_name = smart_listing_name
      @smart_listing = smart_listing
      @template = template
      @options = options
      @proc = proc
    end


    # Renders the main partial (whole list)
    def render_list(locals = {})
      return unless @smart_listing.partial

      @template.render partial: @smart_listing.partial, locals: { smart_listing: self }.merge(locals || {})
    end


    def paginate(_options = {})
      if @smart_listing.pagy_collection.series.size > 1
        render(partial: 'smart_listing/pagination', locals: { pagy: @smart_listing.pagy_collection, remote: @smart_listing.remote? }).html_safe
      end
    end


    # Check if smart list is empty
    def empty?
      @smart_listing.count == 0
    end


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


    def collection
      @smart_listing.collection
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


    private


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


      def default_locals
        { smart_listing: @smart_listing, builder: self }
      end

  end
end
