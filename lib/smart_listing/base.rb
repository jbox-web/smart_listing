# frozen_string_literal: true

module SmartListing
  class Base
    include Pagy::Backend

    attr_reader :name, :collection, :options, :per_page, :sort, :page, :count, :params, :pagy_collection

    # Params that should not be visible in pagination links (pages, per-page, sorting, etc.)
    UNSAFE_PARAMS = %i[authenticity_token commit utf8 _method script_name].freeze

    def initialize(name, collection, options = {})
      @name = name
      @pagy_collection = nil

      config_profile = options.delete(:config_profile)

      @options = {
        partial: @name, # SmartListing partial name
        sort_attributes: :implicit, # allow implicitly setting sort attributes
        default_sort: {}, # default sorting
        href: nil, # set SmartListing target url (in case when different than current url)
        remote: true, # SmartListing is remote by default
        callback_href: nil # set SmartListing callback url (in case when different than current url)
      }.merge(SmartListing.config(config_profile).global_options).merge(options)

      @collection = @options[:array] ? collection.to_a : collection
    end

    # rubocop:disable Layout/LineLength
    def setup(params, cookies)
      @params = params
      @params = @params.to_unsafe_h if @params.respond_to?(:to_unsafe_h)
      @params = @params.with_indifferent_access
      @params.except!(*UNSAFE_PARAMS)

      @page = get_param :page
      @per_page = !get_param(:per_page) || get_param(:per_page).empty? ? (@options[:memorize_per_page] && get_param(:per_page, cookies).to_i > 0 ? get_param(:per_page, cookies).to_i : page_sizes.first) : get_param(:per_page).to_i # rubocop:disable Style/NestedTernaryOperator
      @per_page = page_sizes.first unless page_sizes.include?(@per_page) || (unlimited_per_page? && @per_page == 0)

      @sort = parse_sort(get_param(:sort)) || @options[:default_sort]
      sort_keys = (@options[:sort_attributes] == :implicit ? @sort.keys.collect { |s| [s, s] } : @options[:sort_attributes])

      set_param(:per_page, @per_page, cookies) if @options[:memorize_per_page]

      @count = @collection.size
      @count = @count.length if @count.is_a?(Hash)

      # Reset @page if greater than total number of pages
      if @per_page > 0
        no_pages = (@count.to_f / @per_page.to_f).ceil.to_i # rubocop:disable Style/FloatDivision
        @page = no_pages if @page.to_i > no_pages
      end

      if @options[:array]
        if @sort && !@sort.empty? # when array we sort only by first attribute
          i = sort_keys.index { |x| x[0] == @sort.to_h.first[0] }
          @collection = @collection.sort do |x, y|
            xval = x
            yval = y
            sort_keys[i][1].split('.').each do |m|
              xval = xval.try(m)
              yval = yval.try(m)
            end
            xval = xval.upcase if xval.is_a?(String)
            yval = yval.upcase if yval.is_a?(String)

            if xval.nil? || yval.nil?
              xval.nil? ? 1 : -1
            else
              if @sort.to_h.first[1] == 'asc' # rubocop:disable Style/IfInsideElse
                (xval <=> yval) || (xval && !yval ? 1 : -1)
              else
                (yval <=> xval) || (yval && !xval ? 1 : -1)
              end
            end
          end
        end
        if @options[:paginate] && @per_page > 0
          @pagy_collection, @collection = pagy_array(@collection, page: @page, limit: @per_page, params: pagy_options.fetch(:params, {}).merge(smart_listing_name: name))
        end
      else
        # let's sort by all attributes
        if @sort && !@sort.empty?
          @collection = @collection.order(sort_keys.filter_map { |s| "#{s[1]} #{@sort[s[0]]}" if @sort[s[0]] })
        end
        @pagy_collection, @collection = pagy(@collection, page: @page, limit: @per_page, params: pagy_options.fetch(:params, {}).merge(smart_listing_name: name)) if @options[:paginate] && @per_page > 0
      end
    end
    # rubocop:enable Layout/LineLength

    def partial
      @options[:partial]
    end

    def param_names
      @options[:param_names]
    end

    def param_name(key)
      "#{base_param}[#{param_names[key]}]"
    end

    def unlimited_per_page?
      !!@options[:unlimited_per_page]
    end

    def max_count
      @options[:max_count]
    end

    def href
      @options[:href]
    end

    def callback_href
      @options[:callback_href]
    end

    def remote?
      @options[:remote]
    end

    def page_sizes
      @options[:page_sizes]
    end

    def pagy_options
      @options[:pagy_options]
    end

    def sort_dirs
      @options[:sort_dirs]
    end

    def all_params(overrides = {})
      ap = { base_param => {} }
      @options[:param_names].each do |k, v|
        ap[base_param][v] = overrides[k] || send(k)
      end
      ap
    end

    def sort_order(attribute)
      @sort && @sort[attribute].present? ? @sort[attribute] : nil
    end

    def base_param
      "#{name}_smart_listing"
    end

    private

    def get_param(key, store = @params)
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"]
      else
        store[base_param].try(:[], param_names[key])
      end
    end

    def set_param(key, value, store = @params)
      if store.is_a?(ActionDispatch::Cookies::CookieJar)
        store["#{base_param}_#{param_names[key]}"] = value
      else
        store[base_param] ||= {}.with_indifferent_access
        store[base_param][param_names[key]] = value
      end
    end

    def parse_sort(sort_params)
      sort = nil

      if @options[:sort_attributes] == :implicit
        sort = sort_params.dup.reject { |_k, v| v.blank? } if sort_params.present?
      elsif @options[:sort_attributes]
        @options[:sort_attributes].each do |a|
          k, _v = a
          next unless sort_params && !sort_params[k.to_s].blank?

          dir = %w[asc desc].delete(sort_params[k.to_s])

          if dir
            sort ||= {}.with_indifferent_access
            sort[k] = dir
          end
        end
      end

      sort
    end
  end
end
