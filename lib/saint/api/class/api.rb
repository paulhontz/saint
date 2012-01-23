module Saint
  class ClassApi

    include Saint::Utils
    include Saint::Inflector

    attr_reader :pkey

    # initializing the configuration Api for given node.
    #
    # @param [Object] node
    def initialize node

      @node = node
      @ipp = Saint.ipp
      @order = Hash.new
      @header_args, @header_opts = [], {}

      @create, @update, @delete = true, true, true

      @associations = {
          belongs_to: Hash.new,
          has_n: Hash.new,
      }
      @belongs_to = Hash.new
      @has_n = Hash.new

      @before, @after = Hash.new, Hash.new
      @capabilities = {create: true, update: true, delete: true}
    end

    # *  setting the Api model
    # *  setting the primary key
    # *  extending current node by adding CRUD methods
    #
    # @param [Class] model
    #   should be an valid ORM model. for now only DataMapper ORM supported.
    # @param [Symbol] pkey
    #   the model primary key, `:id`
    def model model = nil, pkey = :id
      if configurable? && model
        @model, @pkey = model, pkey
        # adding CRUD methods to node
        Saint::CrudExtender.new @node
        Saint::ORMUtils.finalize
      end
      @model
    end

    # self-explanatory
    def items_per_page n = nil
      @ipp = n.to_i if n
      @ipp
    end

    alias :ipp :items_per_page

    # the order to be used when items extracted.
    # call it multiple times to order by multiple columns/directions
    #
    # @example
    #    saint.order :date, :desc
    #    saint.order :name, :asc
    #
    # @param [Symbol] column
    # @param [Symbol] direction, `:asc`, `:desc`
    def order column = nil, direction = :asc

      return @order unless column

      raise "Column should be a Symbol,
          #{column.class} given" unless column.is_a?(Symbol)

      raise "Unknown direction #{direction}.
          Should be one of :asc, :desc" unless [:asc, :desc].include?(direction)

      @order[column] = direction if configurable?
    end

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
    # @param [Object] row `nil`
    # @param [Hash] opts
    # @option opts [String] :label
    #   override the label set by #header
    # @option opts [String] :join
    #   the string to join label and header.
    #   if not provided, " | " will be used.
    #   if it is set to nil or false, an array of label and header snippets will be returned.
    def h row = nil, opts = {}
      label = @header_opts[:label] || pluralize(titleize(demodulize(@node)))
      label = opts[:label] if opts.has_key?(:label)
      join = opts.has_key?(:join) ? opts[:join] : ' | '
      header = Array.new
      if @header_proc
        header << @header_proc.call(row).to_s
      else
        args = @header_args
        if row && args.size == 0
          # no snippets defined, so using first 3 non-id columns
          orm = Saint::ORM.new(@node.saint.model)
          orm.properties.each do |p|
            next if (p == :id) || (p.to_s =~ /_id$/i)
            break if args.size == 3
            args << p
          end
          args = ['#' % args.join(', #')]
        end
        args.each do |a|
          (s = column_format(a, row)) && s.strip.size > 0 && header << s
        end
      end
      return [label, header.join].join(label && label.size > 0 && header.size > 0 ? join : '') if join
      [label, *header]
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

    private

    def configurable?
      # !@node.node.mounted? could also be used,
      # but negations negate positiveness :)
      @node.node.mounted? ? false : true
    end

    # initialize the view Api to be used by current configuration Api
    def saint_view
      unless @saint_view
        @saint_view = Presto::View::Api.new
        @saint_view.engine Saint.view.engine
        @saint_view.root Saint.view.root
        @saint_view.scope self
      end
      @saint_view
    end

    def remove_capability capability
      @capabilities[capability] = nil
    end

    def check_capability capability
      @capabilities[capability]
    end

  end
end
