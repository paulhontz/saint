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
    def filter column = nil, type = nil, opts = {}, &proc
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
    #    saint.filters :name, :http
    #
    # @example get http and html filters
    #    saint.filters :name, :http, :html
    #
    # @param [Hash] params
    # @param [Array] *types
    def filters params = nil, *types

      @filters ||= Hash.new
      return @filters unless params

      types = [:orm, :http, :html] if types.size == 0

      seed = Digest::MD5.hexdigest('%s_%s_%s' % [rand, params, types])
      instances = @filters.values.map { |f| FilterInstance.new(f, params, seed) }

      filters = types.compact.map do |type|
        case type
          when :orm
            instances.map { |i| i.send(type) }.inject({}) { |r, e| r.merge(e) }
          when :http
            instances.map { |i| i.send(type) }
          when :html
            if instances.size > 0
              saint_view.render_partial('filter/layout', filters: instances)
            else
              nil
            end
        end
      end
      return filters.first if filters.size == 1
      filters
    end

    # detect if given params contains values for any defined filters
    def filters? params
      filter = nil
      @filters.keys.each { |c| break if filter = filter?(c, params) }
      filter
    end

  end

  class Filter

    include Saint::Utils
    include Saint::Inflector

    attr_reader :node, :type, :id, :var,
                :local_key, :local_pkey, # primary key of searched model
                :local_model, :local_orm, # Model/ORM that returns filtered items to be displayed as search results.
                :remote_model, :remote_orm, # Model/ORM that returns items to be displayed on drop-down selectors.
                :remote_label, :remote_order, :remote_proc, :remote_pkey, :remote_key,
                :remote_associate_via, # define the ORM relation name through which remote model is associated with local model
                :through_model, :through_orm, # Model/ORM that returns primary keys for items to be displayed as search results.
                :through_remote_key, :through_local_key,
                :logic, :logic_prefix, :logic_suffix # defines how the db are queried. see {#logic}

    # initialize new filter
    #
    # @param [Class] node
    # @param [Symbol] column
    # @param type_and_or_opts
    # @option type_and_or_opts [Symbol] column
    # @option type_and_or_opts [Symbol, Array] logic
    # @option type_and_or_opts [String, Symbol] label
    # @option type_and_or_opts [Hash, Array] options options to be used on :select type
    # @option type_and_or_opts [Boolean] multiple
    # @param [Proc] proc
    def initialize node, column, *type_and_or_opts, &proc

      @node, @column = node, column
      unless @local_model = @node.saint.model
        raise 'Please define model before any setup'
      end
      @type, opts = nil, {}
      type_and_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : @type = a }

      @var = column.to_s
      @label = titleize @var.gsub(/_id$/, '')
      @remote_opts, @remote_order = {}, {}
      @remote_pkey = :id

      @depends_on = Array.new
      # orm should support all this methods.
      @logic_map = {
          like: ['%', '%'],
          :~ => [],
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
      logic(:eql) if @type == :boolean

      if options = opts[:options]
        options(*[options].flatten)
      end

      label opts[:label]
      multiple opts[:multiple]

      proc && self.instance_exec(&proc)
      @through_model = @remote_opts[:through]

      @type ||= @remote_model ? :select : :string

      @id = ['saint_filters', @node, @column, @remote_model, @through_model].
          map { |c| c.to_s }.compact.join('-').gsub(/[^\w|\d]/, '_').gsub(/_+/, '_')

      @local_pkey = @node.saint.pkey
      if @local_model.new.respond_to?(@column) || @through_model
        @local_orm = Saint::ORM.new(@local_model)
      end

      remote_setup
      remote_setup__order

      @logic ||= @type == :select ? :eql : :like
      logic_setup
    end

    # sometimes, various filters may need to use same columns.
    # to avoid column names collisions,
    # define the real column by using :column option or `column` method inside block.
    def column column = nil
      @column = column.to_sym if column
      @column
    end

    # define how to build db query.
    # it accepts 3 arguments: logic, prefix, suffix
    #
    # can also be set as option passed to `saint.filter`.
    # value set by block will override value set by option.
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
    # other logic types: :gt, :gte, :lt, :lte, :not
    #
    # @param [Symbol] logic
    # @param [Array] *ps prefix and suffix
    def logic logic = nil, *ps
      if logic
        Saint::ORMUtils.respond_to?(logic) || raise("ORM should respond to #{logic}")
        @logic = @logic_map[logic] ? logic : @logic_map.keys.first
        if ps.size > 0
          @logic_prefix, @logic_suffix = ps
        else
          logic_setup
        end
      end
      @logic
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

    # set remote model as well as middle model, remote opts and remote proc.
    #
    # @param [Object] model remote model
    # @param [Hash] opts
    # @option opts [Object] through
    # @option opts [Symbol] via
    # @option opts [Symbol, Array, Hash] order
    # @option opts [String, Symbol] label
    # @option opts [Symbol] remote_pkey
    # @option opts [Symbol] remote_key
    # @option opts [Symbol] local_key
    # @param [Proc] proc
    def model model = nil, opts = {}, &proc
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
        unless filter = @node.saint.filters[column]
          raise "No filter found by #{column} column"
        end
        @depends_on << filter
      end
      @depends_on
    end

    # return filters that depends on given filter
    def dependant_filters filter = self, level = 0
      @dependant_filters = Array.new if level == 0
      @dependant_filters.concat(@node.saint.filters.values.map do |f|
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
    def self.query_string var, logic = :eql, multiple = false
      "saint-filters[%s][%s]%s" % [var, logic, ('[]' if multiple)]
    end

    # (see #self.query_string)
    def query_string
      self.class.query_string @var, @logic, multiple?
    end

    private

    def logic_setup
      @logic_prefix, @logic_suffix = @logic_map[@logic][0], @logic_map[@logic][1]
    end

    def remote_setup
      return unless @remote_model

      @remote_orm = Saint::ORM.new(@remote_model)
      @remote_pkey = @remote_opts.fetch :remote_pkey, :id
      @remote_label = [@remote_opts.fetch(:label, @remote_orm.properties(true).first)].flatten
      @remote_associate_via = @remote_opts.fetch :via, nil

      if @through_model
        @through_local_key = @remote_opts.fetch :local_key, (singularize(@local_orm.storage_name) + "_id").to_sym
        @through_remote_key = @remote_opts.fetch :remote_key, (singularize(@remote_orm.storage_name) + "_id").to_sym
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
    include Saint::ExtenderUtils
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

      @view_api = Presto::View::Api.new
      @view_api.engine Saint.view.engine
      @view_api.root '%s/filter/' % Saint.view.root
      @view_api.scope self
    end

    # return ORM filters
    def orm

      default_filters = Hash.new
      
      return default_filters unless @val

      if @val.is_a?(Array)
        val = @val.select { |v| v.size > 0 }
        return default_filters unless val.size > 0
      else
        val = [@setup.logic_prefix, @val, @setup.logic_suffix].join
        return default_filters unless val.size > [@setup.logic_prefix, nil, @setup.logic_suffix].join.size
      end

      local_keys = []
      if @setup.remote_orm && @setup.remote_associate_via
        if remote_keys = @setup.remote_orm.filter(@setup.column => val)[0]
          remote_keys.each do |r|
            r.send(@setup.remote_associate_via).each do |o|
              local_keys << o.send(@setup.local_pkey)
            end
          end
        end
      end
      if @setup.through_orm
        if remote_keys = @setup.through_orm.filter(@setup.through_remote_key => val)[0]
          remote_keys.each { |r| local_keys << r.send(@setup.through_local_key) }
        end
      end
      return {@setup.local_pkey => local_keys} if local_keys.size > 0
      return default_filters unless @setup.local_orm
      @setup.local_orm.send(@setup.logic, @setup.column, val)
    end

    # return HTTP query
    def http
      @val.is_a?(Array) ?
          @val.map { |v| '%s=%s' % [@setup.query_string, escape(v)] }.join('&') :
          '%s=%s' % [@setup.query_string, escape(@val)]
    end

    # render filter into UI representation
    def html xhr = false
      @xhr = xhr
      @view_api.render_partial @setup.type
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
        end.compact.join(", ")
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
