module Saint
  class ClassApi

    # filters builder.
    #
    # @example filter by name
    #    saint.filter :name
    #
    # @example filter by author(direct association)
    #    saint.belongs_to :author, Model::Author
    #
    #    saint.filter :author_id do
    #      model Model::Author
    #    end
    #
    # @example filter by menu through MenuPage model
    #    saint.has_n :menus, Model::Menu, Model::MenuPage
    #
    #    saint.filter :menu do
    #      model Model::Menu, through: Model::MenuPage
    #    end
    #
    # @example nested filters
    #
    #  #  say you need to filter pages by authors.
    #  #  you can simply add "saint.filter :author_id", but if you have 10k of authors,
    #  #  they all will be loaded into a single drop-down selector.
    #  #  to narrow down the authors, simply filter them by some attribute, say country.
    #  #  for this, add an :country_id filter before :author_id filter,
    #  #  then add "depends_on :country_id" inside :author_id filter.
    #  #  author model should respond to :country_id for this to work.
    #  #  if pages also responds to :country_id, :country_id filter will also filter pages by country.
    #
    #  saint.belongs_to :author, Model::Author
    #
    #  saint.filter :country_id do
    #    model Model::Country
    #  end
    #  saint.filter :author_id do
    #    model Model::Author
    #    depends_on :country_id
    #  end
    #
    def filter column, *type_and_or_opts, &proc
      return unless configurable?
      type, opts = nil, {}
      type_and_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : type = a.to_sym }
      (@filters ||= Hash.new)[column] = Filter.new(@node, column, type, opts, &proc)
    end

    # if there are an filter defined for given column,
    # create and return a filter instance built upon given HTTP params.
    #
    # @param [Symbol] column
    # @param [Hash] params
    def filter? column, params
      return unless params
      return unless filter = @filters[column]
      instance = FilterInstance.new filter, params
      instance.val
    end

    # detect if given params contains values for any defined filters
    def filters? params
      filter = nil
      @filters.keys.each { |c| break if filter = filter?(c, params) }
      filter
    end

    # by default, Saint will build a filter for each property found on given model.
    #
    # to build filters only for some columns, use `filters` inside #model block
    #
    # @example build filters only for :name and :email
    #    saint.model SomeModel do
    #      filters :name, :email
    #    end
    #
    # to ignore some of them, simply use `filters_ignored`
    #
    # @example build filters for all columns but :visits
    #    saint.model SomeModel do
    #      filters_ignored :visits
    #    end
    #
    # @param [Array] *columns
    def filters *args
      if args.size > 0 && configurable?
        raise 'please call %s only inside #model block' % __method__ if model_defined?
        return @filters_opted = false if args.first == false
        @filters_opted = args
      end
    end

    # (see #filters)
    def filters_ignored *args
      if args.size > 0 && configurable?
        raise 'please call %s only inside #model block' % __method__ if model_defined?
        @filters_ignored = args
      end
    end

    # dual meaning method.
    # if called without arguments, it simply returns actually defined filters,
    # i.e. ones created by "saint.filter"
    # if first argument given, it will create filter instances for all defined filters,
    # using first argument as HTTP params.
    # each instance contains 3 types of filters:
    # * http - the query-string containing actual filters
    # * orm - filters to be applied to ORM operations
    # * html - rendered UI
    #
    # by default, instances will return all types.
    # to get only some types, pass them as arguments.
    #
    # @example get only http filters
    #    saint.get_filters :http.params, :http
    #
    # @example get http and html filters
    #    saint.get_filters http.params, :http, :html
    #
    # @param [Hash] params
    # @param [Array] *types
    def get_filters params = nil, *types

      @filters ||= Hash.new
      return @filters unless params

      types = (types.size == 0 ? [:orm, :http, :html] : types).compact

      seed = Digest::MD5.hexdigest('%s_%s_%s' % [rand, params, types])
      instances = @filters.values.map { |f| FilterInstance.new(f, params, seed) }
      subsets = Hash[types.zip subset_instances(params, *types)]

      filters = types.map do |type|
        case type
          when :orm
            instances.map { |i| i.send(type) }.inject({}) { |f, c| f.update(c) }.update(subsets[type])
          when :http
            instances.map { |i| i.send(type) }.concat(subsets[type])
          when :html
            if instances.size > 0
              saint_view.render_partial('filter/layout', filters: instances)
            else
              nil
            end
        end
      end
      filters.size == 1 ? filters.first : filters
    end

    private
    # automatically build filters based on properties found on given model
    def build_filters

      return unless configurable?
      return if @filters_opted == false

      types = {
          'string' => true,
          'text' => 'string',
          'boolean' => true,
          'date' => true,
          'date_time' => true,
          'time' => true,
      }
      selector(ORMUtils.properties(model), @filters_opted, @filters_ignored).
          map { |n, t| types[t] == true ? [n, t] : [n, types[t]] if types[t] }.compact.
          each { |c| filter *c }
    end

  end

  class Filter

    include Saint::Utils
    include Saint::Inflector

    attr_reader :node, :type, :id, :var, :column_quoted,
                :local_pkey, # primary key of searched model
                :local_model, :local_orm, # Model/ORM that returns filtered items to be displayed as search results.
                :remote_model, :remote_orm, # Model/ORM that returns items to be displayed on drop-down selectors.
                :remote_label, :remote_order, :remote_proc, :remote_pkey,
                :remote_associate_via, # define the ORM relation name through which remote model is associated with local model
                :through_model, :through_orm, # Model/ORM that returns primary keys for items to be displayed as search results.
                :through_remote_key, :through_local_key,
                :logic, :logic_prefix, :logic_suffix # defines how the db are queried. see {#logic}

    attr_reader :local_columns

    # initialize new filter
    #
    # @param [Class] node
    # @param [Symbol] column
    # @param [Symbol] type
    # @param [Hash] opts
    # @param [Proc] proc
    # @option opts [Symbol] column
    # @option opts [Symbol, Array] logic
    # @option opts [String, Symbol] label
    # @option opts [Hash, Array] options options to be used on :select type
    # @option opts [Boolean] multiple
    # @option opts [Boolean] range
    def initialize node, column, type = nil, opts = {}, &proc

      @node, @column, @type = node, column, type
      unless @local_model = @node.saint.model
        raise 'Please define model before any setup'
      end

      @var = column.to_s
      @label = titleize @var.gsub(/_id$/, '')
      @remote_opts, @remote_order = {}, {}
      @remote_pkey = :id

      @depends_on = Array.new
      # orm should support all this methods.
      @logic_map = {
          like: ['%', '%'],
          eql: [],
          gt: [],
          gte: [],
          lt: [],
          lte: [],
          not: [],
      }

      if logic = opts[:logic]
        logic(*[logic].flatten)
      end
      logic(:eql) if boolean?

      if options = opts[:options]
        options(*[options].flatten)
      end

      label opts[:label]
      multiple opts[:multiple]
      range opts[:range]
      range true if date? || date_time? || time? unless opts.has_key?(:range)

      proc && self.instance_exec(&proc)
      @through_model = @remote_opts[:through]

      @type ||= @remote_model ? :select : :string

      @id = ['saint_filters', @node, @column, @remote_model, @through_model].
          map { |c| c.to_s }.compact.join('-').gsub(/[^\w|\d]/, '_').gsub(/_+/, '_')

      @local_pkey = @node.saint.pkey
      if (is_local_filter = @local_model.new.respond_to?(@column)) || @through_model
        @local_orm = Saint::ORM.new(@local_model)
        @column_quoted = @local_orm.quote_column(@column) if is_local_filter
      end

      remote_setup
      remote_setup__order

      @logic ||= @type == :select ? :eql : :like
      logic_setup

      @local_columns = ORMUtils.properties(@local_model, false)
    end

    # sometimes, various filters may need to use same columns.
    # to avoid column names collisions,
    # define the real column by using :column option or `column` method inside block.
    # worth to note that if remote model defined,
    # column will be used to search through remote items,
    # and local model will use only local pkey to fetch local items.
    def column column = nil
      @column = column.to_sym if column
      @column
    end

    # define how to build db query.
    # it accepts 3 arguments: logic, prefix, suffix.
    #
    # can also be set as option passed to `saint.filter`.
    # value set by block will override value set by option.
    #
    # builtin operators: :like, :eql, :gt, :gte, :lt, :lte, :not
    #
    # you can also use your own operator, by passing a string as first argument.
    #
    # @example equality: column = 'val'
    #    saint.filter :column, logic: :eql
    #    # or
    #    saint.filter :column do
    #      logic :eql
    #    end
    #
    # @example equality with prefix: column = 'some value' + val
    #    saint.filter :column, logic: [:eql, 'some value']
    #    # or
    #    saint.filter :column do
    #      logic :eql, 'some value'
    #    end
    #
    # @example equality with suffix: column = val + 'some value'
    #    saint.filter :column, logic: [:eql, nil, 'some value']
    #    # or
    #    saint.filter :column do
    #      logic :eql, nil, 'some value'
    #    end
    #
    # @example equality with prefix and suffix: column = 'prefix' + val + 'suffix'
    #    saint.filter :column, logic: [:eql, 'prefix', 'suffix']
    #    # or
    #    saint.filter :column do
    #      logic [:eql, 'prefix', 'suffix']
    #    end
    #
    # @example default LIKE: column LIKE '%val%'
    #    saint.filter :column
    #
    # @example column LIKE '%val'
    #    saint.filter :column, logic: [:like, '%']
    #    # or
    #    saint.filter :column do
    #      logic :like, '%'
    #    end
    #
    # @example column LIKE 'val%'
    #    saint.filter :column, logic: [:eql, nil, '%']
    #    # or
    #    saint.filter :column do
    #      logic :eql, nil, '%'
    #    end
    #
    # @example SELECT ... WHERE name ILIKE '%[value]%'
    #    saint.filter :name, logic: 'ILIKE'
    #    # or
    #    saint.filter :name do
    #      logic 'ILIKE'
    #    end
    #
    # @example SELECT ... WHERE name ~ '^[value]'
    #    saint.filter :name, logic: ['~', '^']
    #    # or
    #    saint.filter :name do
    #      logic '~', '^'
    #    end
    #
    # @example SELECT ... WHERE name ~ '[value]$'
    #    saint.filter :name, logic: ['~', '', '$']
    #    # or
    #    saint.filter :name do
    #      logic '~', '', '$'
    #    end
    #
    # @param [Symbol] logic
    # @param [Array] *ps prefix and suffix
    def logic logic = nil, *ps
      return @logic unless logic
      if logic.is_a?(Symbol)
        Saint::ORMUtils.respond_to?(logic) || raise("ORM should respond to #{logic}")
        @logic = @logic_map[logic] ? logic : @logic_map.keys.first
        if ps.size > 0
          @logic_prefix, @logic_suffix = ps
        else
          logic_setup
        end
      else
        @logic = logic
        @logic_prefix, @logic_suffix = ps
      end
    end

    # set label for current filter.
    # can also be set as option passed to `saint.filter`.
    # value set by block will override value set by option.
    def label label = nil
      @label = label if label
      @label
    end

    # define options for drop-down filters.
    #
    # @example using Hash
    #    saint.filter :status, :select, options: {1 => 'Active', 0 => 'Suspended'}
    #    # or
    #    saint.filter :status, :select do
    #        options 1 => 'Active', 0 => 'Suspended'
    #    end
    #
    # @example using Array
    #    saint.filter :color, :select, options: ['red', 'green', 'blue']
    #    # or
    #    saint.filter :color do
    #        options 'red', 'green', 'blue'
    #    end
    #
    # can also be set as option passed to `saint.filter`.
    # value set by block will override value set by option.
    def options *args
      if (args = args.flatten).size > 0
        if args.first.is_a?(Hash)
          @options = args.first
        else
          @options = Hash[args.zip args]
        end
      end
      @options || {}
    end

    # used on :select and associative filters.
    # if set to true, drop-down selectors will allow to select multiple options
    #
    # can also be set as option passed to `saint.filter`.
    # value set by block will override value set by option.
    def multiple *args
      @multiple = args.first if args.size > 0
      @multiple
    end

    def multiple?
      @multiple
    end

    # used on :select and :string filters.
    # if set to true, filter will display two fields - min and max
    def range *args
      @range = args.first if args.size > 0
      @range
    end

    def range?
      @range
    end

    # set remote model as well as middle model, remote opts and remote proc.
    #
    # @param [Object] model remote model
    # @param [Hash] opts
    # @option opts [String, Symbol] label
    # @option opts [Symbol, Array, Hash] order
    # @option opts [Object] through
    # @option opts [Symbol] via
    # @option opts [Symbol] pkey
    # @option opts [Symbol] remote_key
    # @option opts [Symbol] local_key
    # @param [Proc] proc
    def model model, opts = {}, &proc
      @remote_model, @remote_opts, @remote_proc = model, opts, proc
    end

    # building nested filters.
    # say you have to filter games by edition.
    # it is easy to add "saint.filter :edition_id, Model::Edition" and
    # get an drop-down with all editions.
    # but what if there are many thousands of editions.
    # they all will be displayed in one drop-down and that's bad.
    # to solve this, simply filter editions by competition,
    # by adding :competition_id filter before :edition_id filter,
    # and then add "depends_on :competition_id" inside :edition_id filter.
    #
    # @example
    #    saint.model DB::Game
    #
    #    saint.filter :region_id, DB::Region
    #
    #    saint.filter :competition_id, DB::Competition do
    #      depends_on :region_id
    #    end
    #
    #    saint.filter :edition_id, DB::Edition do
    #      depends_on :competition_id
    #    end
    #
    #    # this will build 3 filters: Region, Competition and Edition.
    #    # region is used to narrow down competitions,
    #    # and competitions are used to narrow down editions.
    #    # games will be filtered only when :edition_id filter get an value,
    #    # cause Game model respond only to :edition_id and does not respond to any of :region_id or :competition_id.
    # 
    # @param [Array] *columns
    def depends_on *columns
      columns.each do |column|
        unless filter = @node.saint.get_filters[column]
          raise "No filter found by #{column} column"
        end
        @depends_on << filter
      end
      @depends_on
    end

    # return filters that depends on given filter
    def dependant_filters filter = self, level = 0
      @dependant_filters = Array.new if level == 0
      @dependant_filters.concat(@node.saint.get_filters.values.map do |f|
        next if f.depends_on.select { |pf| pf.__id__ == filter.__id__ }.size == 0
        dependant_filters(f, level+1)
        f
      end.compact)
      @dependant_filters
    end

    # build the query string from given var and logic
    #
    # @param [String] var
    # @param [Symbol] logic
    def self.query_string var, logic = :eql, *args
      args = args.map { |a| '[%s]' % (a == true ? '' : a.to_s) if a }.compact.join
      'saint-filters[%s][%s]%s' % [var, logic, args]
    end

    # (see #self.query_string)
    def query_string *args
      self.class.query_string @var, @logic, *[args, multiple?].flatten
    end

    def string?
      @type == :string
    end

    def boolean?
      @type == :boolean
    end

    def date?
      @type == :date
    end

    def date_time?
      @type == :date_time
    end

    def time?
      @type == :time
    end

    private

    def logic_setup
      case
        when @logic.is_a?(Symbol)
          @logic_prefix, @logic_suffix = *@logic_map[@logic]
        when @logic.is_a?(String)
          @logic_prefix, @logic_suffix = *@logic_map[:like] if @logic =~ /like/i
      end
    end

    def remote_setup
      return unless @remote_model

      @remote_orm = Saint::ORM.new(@remote_model)
      @remote_pkey = @remote_opts.fetch :pkey, :id
      @remote_label = [@remote_opts.fetch(:label, @remote_orm.properties.keys.first)].flatten
      @remote_associate_via = @remote_opts.fetch :via, tableize(demodulize @local_model)

      if @through_model
        @through_local_key = @remote_opts.fetch :local_key, foreign_key(@local_model)
        @through_remote_key = @remote_opts.fetch :remote_key, foreign_key(@remote_model)
        @through_orm = Saint::ORM.new(@through_model)
      end
    end

    def remote_setup__order
      return unless @remote_model
      return unless order = @remote_opts[:order]

      @remote_order = {@remote_pkey => :desc}
      case
        when order.is_a?(Hash)
          @remote_order = order.keys.inject({}) do |o, c|
            d = order[c]
            raise('Direction should be one of :asc or :desc, %s [%s] given' % [d, d.class]) unless [:asc, :desc].include?(d)
            o.update c.to_sym => d
          end
        when order.is_a?(Array)
          @remote_order = order.inject({}) { |o, c| o.update c.to_sym => :asc }
        when order.is_a?(Symbol), order.is_a?(String)
          @remote_order = {order.to_sym => :asc}
      end
      @remote_order
    end

  end

  class FilterInstance

    include Saint::Inflector
    include Saint::Utils
    include Rack::Utils

    attr_reader :val, :depends_on

    def initialize setup, params, seed = ''

      @setup, @params, @seed = setup, params, seed

      @id = '%s%s' % [@setup.id, @seed]

      @val = extract_val

      @depends_on = Hash.new
      @setup.depends_on.each do |f|
        @depends_on[f] = extract_val(f)
      end
    end

    # return ORM filters
    def orm

      default_filters = Hash.new

      return default_filters unless @val
      return default_filters if @setup.dependant_filters.size > 0

      # handling ranges
      if @val.is_a?(Hash)
        min, max = @val.values_at('min', 'max').map { |v| v if v && v.size > 0 }
        if min && max
          default_filters.update ORMUtils.gte(@setup.column, min).merge(ORMUtils.lte(@setup.column, max))
        else
          default_filters.update ORMUtils.gte(@setup.column, min) if min
          default_filters.update ORMUtils.lte(@setup.column, max) if max
        end
        return default_filters
      end

      # handling arrays
      if @val.is_a?(Array)
        val = @val.select { |v| v.size > 0 }
        return default_filters unless val.size > 0
      else
        val = [@setup.logic_prefix, @val, @setup.logic_suffix].join
        return default_filters unless val.size > [@setup.logic_prefix, nil, @setup.logic_suffix].join.size
      end

      local_keys = []

      if @setup.remote_orm && @setup.remote_associate_via && @setup.string?
        (@setup.remote_orm.filter(orm_filters val)[0]||[]).each do |r|
          r.send(@setup.remote_associate_via).each do |o|
            local_keys << o.send(@setup.local_pkey)
          end
        end
      end

      if @setup.through_orm
        (@setup.through_orm.filter(@setup.through_remote_key => val)[0]||[]).each do |r|
          local_keys << r.send(@setup.through_local_key)
        end
      end

      return {@setup.local_pkey => local_keys} if local_keys.size > 0
      return {@setup.local_pkey => nil} unless @setup.local_columns[@setup.column]
      return default_filters unless @setup.local_orm
      orm_filters val
    end

    # return HTTP query
    def http
      if @val.is_a?(Hash)
        query_string = []
        @val.each_pair { |k, v| query_string << '%s[%s]=%s' % [@setup.query_string, escape(k), escape(v)] }
        return query_string.join('&')
      end
      @val.is_a?(Array) ?
          @val.map { |v| '%s=%s' % [@setup.query_string, escape(v)] }.join('&') :
          '%s=%s' % [@setup.query_string, escape(@val)]
    end

    # render filter into UI representation
    def html xhr = false
      @xhr = xhr
      partial = ::File.join('filter', @setup.type.to_s)
      if @setup.range?
        %w[min max].map { |c| saint_view.render_partial partial, range_cardinality: c }.join
      else
        saint_view.render_partial partial, range_cardinality: nil
      end
    end

    # get HTTP value for given filter.
    # if given column is same as column for current filter,
    # return value extracted at filter initialization.
    #
    # @param [Symbol] column
    def filter? column
      return @val if column == @setup.column
      @setup.node.saint.filter? column, @params
    end

    # see Saint::ClassApi::Filter#label
    def label
      @setup.label
    end

    private

    # build orm filters
    def orm_filters val
      if @setup.logic.is_a?(Symbol)
        Saint::ORMUtils.send @setup.logic, @setup.column, val
      else
        Saint::ORMUtils.sql @setup.logic, @setup.column_quoted, val
      end
    end

    # get options for drop-down selector
    def drop_down_options

      options = @setup.options
      options = Hash[options.zip options] if options.is_a?(Array)
      unless options.is_a?(Hash)
        raise ':options should be an Array or an Hash, %s given' % options.class
      end
      return options unless @setup.remote_model

      filters = (@setup.remote_proc && self.instance_exec(&@setup.remote_proc)) || {}

      @depends_on.select { |f, v| v }.each_pair do |f, v|
        v = [f.logic_prefix, v, f.logic_suffix].compact.join
        filters.update(f.remote_orm.send(f.logic, f.column, v))
      end

      # if current filter depends on some up filter,
      # and neither of up or current filter has an value,
      # build drop-down with empty options
      return {} if @setup.depends_on.size > 0 && filters.size == 0

      options = Hash.new
      order = @setup.remote_orm.order(@setup.remote_order)
      remote_items, @errors = @setup.remote_orm.filter(filters.merge(order))
      if @errors.size > 0
        @errors << 'ORM Filters: %s' % @setup.node.http.escape_html(filters.inspect)
        return saint_view.render_partial('error')
      end
      remote_items.each do |remote_item|
        value = @setup.remote_label.map do |c|
          val = Saint::Utils.column_format c, remote_item
          val.size > 0 ? val : nil
        end.compact.join(', ')
        options[remote_item.send(@setup.remote_pkey)] = value
      end
      options
    end

    # fetch HTTP value for current filter
    def extract_val setup = @setup
      return unless (params = @params['saint-filters']) &&
          (var = params[setup.var]) &&
          (val = var[setup.logic.to_s]) &&
          (val.size > 0)
      val.is_a?(String) && val =~ /^\d+$/ ? val.to_i : val
    end

  end

end
