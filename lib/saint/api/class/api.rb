module Saint
  class ClassApi

    include Saint::Utils
    include Saint::Inflector

    # initializing the configuration Api for given node.
    #
    # @param [Object] node
    def initialize node

      @node = node
      @ipp = Saint.ipp
      @pkey = :id
      @header_args, @header_opts = [], {}

      @create, @update, @delete, @dashboard = true, true, true, true

      @associations = {
          belongs_to: Hash.new,
          has_n: Hash.new,
      }
      @belongs_to = Hash.new
      @has_n = Hash.new

      @before, @after = Hash.new, Hash.new
      @capabilities = {create: true, update: true, delete: true}

      @view_scope = self
    end

    # *  setting the Api model
    # *  setting the primary key
    # *  extending current node by adding CRUD methods
    #
    # @param [Class] model
    #   should be an valid ORM model. for now only DataMapper ORM supported.
    # @param [Symbol] pkey
    #   the model primary key, `:id`
    # @param [Proc] proc
    def model model = nil, pkey = nil, &proc
      if configurable? && model
        ORM.new(model).properties.each_pair do |name, type|
          column name, type unless columns_ignored.include?(name)
        end
        @model = model
        @pkey = pkey if pkey
        # adding CRUD methods to node
        Saint::CrudExtender.new @node
      end
      @model
    end

    # define primary key.
    # also can be defined by passing it as second argument to {#model}
    #
    # @param [Symbol] key
    def pkey key = nil
      @pkey = key if configurable? && key
      @pkey
    end

    # set the order to be used when items extracted.
    # by default, Saint will arrange items by primary key, in descending order.
    # this method is aimed to override default order.
    # call it multiple times to order by multiple columns/directions.
    #
    # @example
    #    saint.order :date, :desc
    #    saint.order :name, :asc
    #
    # @param [Symbol] column
    # @param [Symbol] direction, `:asc`, `:desc`
    def order column = nil, direction = :asc
      if column && configurable?
        raise "Column should be a Symbol,
          #{column.class} given" unless column.is_a?(Symbol)
        raise "Unknown direction #{direction}.
          Should be one of :asc, :desc" unless [:asc, :desc].include?(direction)
        (@order ||= Hash.new)[column] = direction
      end
      @order || {pkey => :desc}
    end

    # self-explanatory
    def items_per_page n = nil
      @ipp = n.to_i if n
      @ipp
    end

    alias :ipp :items_per_page

    # define the header to be displayed in UI.
    # header is defaulted to pluralized class name.
    # 
    # @example
    #    class Page
    #      include Saint::Api
    #
    #      # as header is defaulted to pluralized class name,
    #      # Page.saint.h will return "Pages"
    #
    #      # setting custom header label:
    #      saint.header label: 'CMS Pages'
    #      # now Page.saint.h and Page.saint.h(page) will return "CMS Pages"
    #
    #      # setting custom header for defined pages:
    #      saint.header :name, ' (by #author.name)'
    #      # now Page.saint.h will return "Pages"
    #      # however, Page.saint.h(page) will return "Pages | page.name (by page.author.name)"
    #      # IMPORTANT! if page has no author, ' (by #author.name)' will be ignored,
    #      # and Page.saint.h(page) will return only "Pages | page.name"
    #
    #      # setting custom header for defined pages with custom label:
    #      saint.header '#name', ' (by #author.name)', label: 'CMS Pages'
    #      # now Page.saint.h will return "CMS Pages"
    #      # and Page.saint.h(page) will return "CMS Pages | page.name (by page.author.name)"
    #
    #      # setting custom header using a block with default label:
    #      saint.header do |page|
    #        if page
    #          "#{page.name} (by #{page.author.name})"
    #        end
    #      end
    #      # now Page.saint.h will return "Pages"
    #      # and Page.saint.h(page) will return "Pages: page.name (by page.author.name)"
    #
    #      # setting custom header using a block with custom label:
    #      saint.header label: 'CMS Pages' do |page|
    #        "#{page.name} (by #{page.author.name})" if page
    #      end
    #      # now Page.saint.h will return "CMS Pages"
    #      # and Page.saint.h(page) will return "CMS Pages | page.name (by page.author.name)"
    #
    #    end
    #
    def header *format_and_or_opts, &proc
      return unless configurable?
      format_and_or_opts.each do |a|
        a.is_a?(Hash) ? @header_opts.update(a) : @header_args << a
      end
      @header_proc = proc if proc
    end

    # evaluate earlier defined header.
    # (see #header)
    #
    # @example
    #
    #    class Page
    #      include Saint::Api
    #
    #      saint.header :name, ', by #author.name'
    #      # saint.h(page) for a page with author will return "Pages | page.name, by page.author.name"
    #      # saint.h(page, join: ' / ') for a page with author will return "Pages / page.name, by page.author.name"
    #      # saint.h(page, join: false) for a page with author will return ["Pages", page.name, by page.author.name]
    #      # saint.h(page) for a page without author will return "Pages | page.name"
    #      # saint.h(page, join: ' / ') for a page without author will return "Pages / page.name"
    #      # saint.h(page, join: false) for a page without author will return ["Pages", page.name]
    #
    #    end
    #
    # @param [Hash] *row_or_opts
    # @option row_or_opts [String] :label
    #   override the label set by #header
    # @option row_or_opts [String] :join
    #   the string to join label and header.
    #   if not provided, a coma will be used.
    #   if it is set to nil or false, an array of label and header snippets will be returned.
    def h *row_or_opts

      row, opts = nil, {}
      row_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : row = a }

      label = opts.fetch :label, @header_opts[:label]
      join = opts.fetch :join, ', '
      header = Array.new

      if @header_proc
        header << @header_proc.call(row).to_s
      else
        args = @header_args
        if row && args.size == 0
          # no snippets defined, so using first non-id column
          orm = Saint::ORM.new(@node.saint.model)
          args = [orm.properties.keys.first]
        end
        args.each do |a|
          (s = column_format(a, row)) && s.strip.size > 0 && header << s
        end
      end

      if join
        h = [label, header.join].compact.join(join)
        if length = opts[:length]
          h = '%s...' % h[0, length] if h.size > length
        end
        return h
      end
      [label, *header].compact
    end

    # prohibit :create operation
    # @example
    #    saint.create false
    def create *args
      remove_capability __method__ if configurable? && args.size > 0
      check_capability __method__
    end

    # prohibit :update operation
    # @example
    #    saint.update false
    def update *args
      remove_capability __method__ if configurable? && args.size > 0
      check_capability __method__
    end

    # prohibit :delete operation
    # @example
    #    saint.delete false
    def delete *args
      remove_capability __method__ if configurable? && args.size > 0
      check_capability __method__
    end

    alias :remove :delete

    # callbacks to be executed before/after given ORM action(s).
    # if no actions given, callbacks will be executed before any action.
    #
    # proc will receive the managed row as first argument(except #destroy action)
    # and can update it accordingly.
    # performed action will be passed as second argument.
    # proc will be executed inside node instance, so all Api available.
    #
    # available actions:
    # *  save - fires when new item created or existing item updated
    # *  delete - fires when an item deleted
    # *  destroy - fires when all items are deleted
    #
    # @param [Array] *actions
    # @param [Proc] &proc
    def before *actions, &proc
      if configurable? && proc
        actions = ['*'] if actions.size == 0
        actions.each { |a| @before[a] = proc }
      end
      @before
    end

    # (see #before)
    def after *actions, &proc
      if configurable? && proc
        actions = ['*'] if actions.size == 0
        actions.each { |a| @after[a] = proc }
      end
      @after
    end

    def render_dashboard scope
      @rendered_dashboard ||= saint_view(scope).render_layout(saint_view(scope).render_partial('dashboard'))
    end

    # should the controller be displayed on dashboard?
    def dashboard *args
      @dashboard = args.first if args.size > 0
      @dashboard
    end

    # get the label earlier set by `header`
    def label opts = {}
      l = (@label ||= ((hl = @header_opts[:label]) && hl.to_s) || pluralize(titleize(demodulize(@node))))
      opts[:singular] ? singularize(l) : l
    end

    private
    def configurable?
      @node.node.configurable?
    end

    def remove_capability cap
      @capabilities[cap] = nil
    end

    def check_capability cap
      @capabilities[cap]
    end

  end
end
