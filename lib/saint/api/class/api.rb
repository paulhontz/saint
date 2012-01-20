module Saint
  class ClassApi

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

    # define the header to be displayed in UI
    #
    # @example
    #
    #    region = Region.new(name: 'England')
    #    competition = Competition.new(name: 'Championship', region: region)
    #    edition = Edition.new(name: 2011, competition: competition)
    #
    #    # set header
    #    saint.header 'Editions', :name
    #    # get header
    #    saint.h #=> Editions
    #    saint.h(edition) #=> 2011
    #
    #    # set header
    #    saint.header 'Editions', '(\##id) #name'
    #    # get header
    #    saint.h #=> Editions
    #    saint.h(edition) #=> (#1) 2011
    #
    #    # set header
    #    saint.header 'Editions', 'competition.name', :name
    #    # get header
    #    saint.h #=> Editions
    #    saint.h(edition) #=> Championship, 2011
    #
    #    # set header
    #    saint.header 'Editions', '#competition.region.name, #competition.name', :name, join: ' / '
    #    # get header
    #    saint.h #=> Editions
    #    saint.h(edition) #=> England, Championship / 2011
    #
    #    # set header
    #    saint.header 'Editions' do |row|
    #      if row
    #        "<a href='#{row.competition.url}'>#{row.competition.name}</a> / #{row.name}"
    #      end
    #    end
    #    # get header
    #    saint.h #=> Editions
    #    saint.h(some_edition) #=> <a href='/competitions/championship'>Championship</a> / 2011
    #
    # @param [String, Symbol] label
    #   label to be used on summary pages
    # @param [Array] *args
    #   snippets to be used on CRUD pages.
    #   snippets may contain static strings/symbols as well as methods.
    # @param [Proc] &proc
    #   ignore any snippets and use value returned by proc.
    #   proc receives current row as first argument.
    def header label, *args, &proc
      return unless configurable?
      @header_label = label
      @header_args, @header_opts = [], {}
      args.each { |a| a.is_a?(Hash) ? @header_opts.update(a) : @header_args << a }
      @header_proc = proc if proc.is_a?(Proc)
    end

    # evaluate earlier defined header.
    # (see #header)
    def h row = nil, scope = nil

      header = []
      if @header_proc
        val = @header_proc.call(row, scope).to_s
        header << val if val.size > 0
      else
        if row && @header_args.size > 0
          header << @header_args.map do |a|
            val = Saint::Utils.column_format a, row
            val.size > 0 ? val : nil
          end.compact.join(@header_opts[:join] || ', ')
        end
      end
      header.size > 0 ? header.join(' | ') : @header_label || pluralize(titleize(demodulize(@node)))
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
