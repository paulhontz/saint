module Saint
  class Pager

    include Rack::Utils
    include Saint::Utils

    VAR = "saint-page"
    SIDE_PAGES = 5
    ITEMS_PER_PAGE = 10

    attr_reader :items, :items_per_page, :pages, :page_label, :page_number, :html

    def initialize page = 1, items = ITEMS_PER_PAGE, items_per_page = ITEMS_PER_PAGE

      @items, @items_per_page = items, items_per_page
      @pages = (@items.to_f / @items_per_page.to_f).ceil
      @pages = 1 if @pages < 1

      @page_label = page.to_i
      @page_label = 1 if @page_label < 1
      @page_label = @pages if @page_label > @pages && @pages > 1
      @page_number = @page_label - 1
    end

    def paginate opts = {}

      @opts = opts

      @filters_string = @opts[:query] || build_nested_query(@opts[:filters]||{})
      @query_string = [
          "?",
          @filters_string,
          (@filters_string.size > 0 ? "&" : ""),
          "%s=[__%s__]" % [VAR, VAR],
      ].join

      @route = @opts[:route].to_s + @query_string

      side_pages = opts[:side_pages] || SIDE_PAGES

      @page_min = @page_label - side_pages
      @page_min = @pages - side_pages * 2 if (@page_label + side_pages) > @pages
      @page_max = @page_label + side_pages
      @page_max = side_pages * 2 if @page_label < side_pages

      @page_max = @pages if @page_max > @pages
      @page_min = 1 if @page_min < 1

      @page_prev = @page_label > 1 ? @page_label - 1 : nil
      @page_next = @page_label < @pages ? @page_label + 1 : nil

      return if opts[:skip_render]

      @html = saint_view.render_partial(::File.join('pager', (@opts[:template] || :default).to_s))
      self
    end

    # returns query string including page var
    def query_string *page_or_params
      page, params = @page_label, {}
      page_or_params.each { |a| a.is_a?(Hash) ? params.update(a) : page = a }
      link_page(page, '%s%s%s' % [@query_string, ('&' if params.size > 0), build_nested_query(params)])
    end

    # returns query string without page var
    def filters_string
      '?' << @filters_string
    end

    def link_page page, route = nil
      route ||= @route
      route.to_s.sub('[__%s__]' % VAR, page.to_s)
    end

  end
end
