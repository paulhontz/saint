module Saint
  class ClassApi

    # add a GUI filter
    #
    # @example filter by name
    #    saint.filter :name
    #
    # @example filter by author(direct association)
    #    saint.belongs_to :author, Model::Author
    #
    #    saint.filter :author_id, Model::Author
    #
    # @example filter by menu(through association)
    #    saint.has_n :menus, Model::Menu, Model::MenuPage
    #
    #    saint.filter :menu, Model::Menu, Model::MenuPage
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
    #  saint.filter :country_id, Model::Country
    #  saint.filter :author_id, Model::Author do
    #    depends_on :country_id
    #  end
    #
    def filter column = nil, remote_model = nil, through_model = nil, &proc
      (@filters ||= Hash.new)[column] = Filter.new(@node, column, remote_model, through_model, &proc)
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

    # detect if HTTP params contains values for any defined filters
    def filters? params
      filter = nil
      @filters.keys.each { |c| break if filter = filter?(c, params) }
      filter
    end

  end

  class Filter

    include Saint::Utils
    include Saint::Inflector

    attr_reader :id, # unique identity for each filter
                :var, # var used in HTTP params
                :node, # class holding filter
                :local_pkey, # primary key of searched model
                :local_model, :local_orm, # Model/ORM that returns filtered items to be displayed as search results.
                :remote_model, :remote_orm, # Model/ORM that returns items to be displayed on drop-down selectors.
                :through_model, :through_orm, # Model/ORM that returns primary keys for items to be displayed as search results.
                :type_tpl, # template to be rendered. see {#type}
                :type_opts, # options to be used when rendering filter(e.g. {multiple: true} or {style: "width: 100px;"} ). see {#type}
                :type_proc, # an block that should return options to be used when rendering an drop-down selector. see {#type}
                :logic, :logic_prefix, :logic_suffix # defines how the db are queried. see {#logic}

    def initialize node, column, remote_model = nil, through_model = nil, &proc

      @node, @column, @var = node, column, column.to_s
      @label = titleize @var.gsub(/_id$/, '')

      @id = [
          'saint_filters', @node, remote_model, through_model, @var
      ].map { |c| c.to_s }.join('_').gsub(/[^\w|\d|\-]/, '_').gsub(/_+/, '_')

      unless @local_model = @node.saint.model
        raise "Please define model before any setup"
      end
      @local_pkey = @node.saint.pkey
      if @local_model.new.respond_to?(@column) || through_model
        @local_orm = Saint::ORM.new(@local_model)
      end

      if @remote_model = remote_model
        @remote_orm = Saint::ORM.new(@remote_model)
        @remote_pkey = :id
        @default_remote_columns = Array.new
        @remote_orm.properties.each do |p|
          next if (p == :id) || (p.to_s =~ /_id$/i)
          break if @default_remote_columns.size == 2
          @default_remote_columns << p
        end

        if @through_model = through_model
          @through_orm = Saint::ORM.new(@through_model)
          local_table, remote_table = @local_orm.storage_name, @remote_orm.storage_name
          @local_key = (singularize(local_table) + "_id").to_sym
          @remote_key = (singularize(remote_table) + "_id").to_sym
        end
      end

      @type_opts = Hash.new
      @order = Hash.new

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

      @depends_on = Array.new

      proc && self.instance_exec(&proc)
      @type_tpl ||= :select if @remote_model
      @type_tpl ||= :string

      @logic ||= @type_tpl == :select ? :eql : :like
      logic_setup
    end

    # define what/how columns will be displayed in drop-down selector that displays remote items.
    # by default it takes first two non id columns from remote model.
    # however this is unsuitable in most cases.
    # 
    # feel free to use same syntax as per saint.header(see {Saint::ClassApi#header})
    #
    # @example display "name (email)" instead of defaulted "name, email"
    #
    #    # "saint.filter :author_id, Model::Author" will create drop-down options like:
    #    # <option value='ID'>name, email</option>
    #    # add "option_label '#name (#email)'" inside filter block and options will be rendered like:
    #    # <option value='ID'>name (email)</option>
    #
    #    saint.filter :author_id, Model::Author do
    #      option_label '#name (#email)'
    #    end
    #
    # define multiple columns by calling this method multiple times
    #
    # @param [Array] *columns
    def option_label *columns
      columns.each { |column| (@opted_remote_columns ||= Array.new) << column }
    end

    # return earlier defined remote columns or first two non id remote columns
    def remote_columns
      @opted_remote_columns || @default_remote_columns
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

    # set the template to be used when filter rendered.
    # for now :string and :select templates available.
    # 
    # if second arg is an hash, it will be treated as options for rendered html element,
    # e.g. !{multiple: true} or !{class: 'some-css-class'}
    #
    # this method also accepts an block.
    # if block returns a positive value,
    # returned value will be used at rendering.
    # normally, it should return an string for :string type
    # and an hash for :select type.
    # IMPORTANT: if block returns nil, filter ui are not displayed at all.
    #
    # @example add an drop-down filter containing rounds of selected edition
    #    saint.filter :round_id do
    #      logic :eql
    #      label 'Please select Edition'
    #      type :select do
    #        values = {'' => 'Any Round'}
    #        if val = filter?(:edition_id)
    #          DB::Round.all(edition_id: val).each { |r| values[r.id] = round.name }
    #        end
    #        values
    #      end
    #    end
    #
    #    # this will looking for on edition_id in HTTP params and when it is available,
    #    # it will draw an drop-down selector for rounds of selected edition.
    #
    # @example draw and drop-down selector that allow to select multiple options and has an custom css style
    #
    #    saint.filter :author_id do
    #      type :select, multiple: true, style: "width: 100px;"
    #    end
    #
    # @param [Symbol] type
    # @param [Hash] opts
    # @param [Proc] &proc
    def type type = nil, opts = {}, &proc
      return @type_tpl if type.nil?
      @type_tpl, @type_opts = type, opts
      @type_proc = proc if proc
    end

    # sometimes used column should be just an informative label.
    # use this method to define column to be used by ORM
    #
    # @example instruct ORM to use #name instead of #country_name
    #    saint.column :country_name, Model::Country do
    #      column :name
    #    end
    def column column = nil
      @column = column if column
      @column
    end

    # define how to build db query.
    # it accepts 3 arguments: logic, prefix, suffix
    #
    # @example equality: column = 'val'
    #    saint.logic :eql
    #
    # @example equality with prefix: column = 'some value' + val
    #    saint.logic :eql, 'some value'
    #
    # @example equality with suffix: column = val + 'some value'
    #    saint.logic :eql, nil, 'some value'
    #
    # @example equality with prefix and suffix: column = 'prefix' + val + 'suffix'
    #    saint.logic :eql, 'prefix', 'suffix'
    #
    # @example default LIKE: column LIKE '%val%'
    #    saint.logic :like
    #
    # @example column LIKE '%val'
    #    saint.logic :like, '%'
    #
    # @example column LIKE 'val%'
    #    saint.logic :eql, nil, '%'
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

    # filter remote items.
    # 
    # @example display in drop-down selector only active regions
    #    saint.filter :region_id, Model::Region do
    #      filter active: 1
    #    end
    #
    # @param [Hash] filters
    def filter filters = {}, &proc
      filters() << [filters, proc]
    end

    # return earlier defined filters
    def filters
      @filters ||= []
    end

    # set the order for remote items displayed as options of drop-down selector.
    # relevant for drop-down filters.
    # order can be specified multiple times.
    #
    # @param [Symbol] column
    # @param [Symbol] direction
    def order column = nil, direction = :asc
      return @order unless column
      unless [:asc, :desc].include?(direction)
        raise "direction should be one of :asc or :desc"
      end
      @order[column] = direction
    end

    # by default, remote_pkey is :id.
    # use this method to define custom pkey
    #
    # @param [Symbol] key
    def remote_pkey key = nil
      @remote_pkey = key if key
      @remote_pkey
    end

    # valuable for through filters.
    # it defines keys in through table.
    #
    # @param [Symbol] key
    def local_key key = nil
      @local_key = key if key
      @local_key
    end

    # (see #local_key)
    def remote_key key = nil
      @remote_key = key if key
      @remote_key
    end

    # label to be displayed in UI
    #
    # @param [String] label
    def label label = nil
      @label = label if label
      @label
    end

    # build the query string from given var and logic
    #
    # @param [String] var
    # @param [Symbol] logic
    def self.query_string var, logic = :eql
      "saint-filters[%s][%s]%s" % [var, logic, ('[]' if @multiple)]
    end

    # (see #self.query_string)
    def query_string
      self.class.query_string @var, @logic
    end

    private

    def logic_setup
      @logic_prefix, @logic_suffix = @logic_map[@logic][0], @logic_map[@logic][1]
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

      @view_api = Presto::View::Api.new
      @view_api.engine Saint.view.engine
      @view_api.root '%s/filter/' % Saint.view.root
      @view_api.scope self
    end

    # return orm filters
    def orm
      return {} unless @setup.local_orm && @setup.column && @val
      if @setup.through_orm
        # @val is effectively the remote item pkey
        local_keys = []
        if remote_keys = @setup.through_orm.filter(@setup.remote_key => @val)[0]
          remote_keys.each { |r| local_keys << r.send(@setup.local_key) }
        end
        @setup.local_orm.eql(@setup.local_pkey, local_keys)
      else
        @setup.local_orm.send(
            @setup.logic,
            @setup.column,
            [@setup.logic_prefix, @val, @setup.logic_suffix].compact.join
        )
      end
    end

    # return HTTP query
    def http
      "#{query_string}=#{escape @val}"
    end

    # render filter into UI representation
    def html xhr = false
      @xhr = xhr
      if proc = @setup.type_proc
        return unless @type_values = self.instance_exec(&proc)
      end
      @view_api.render_partial @setup.type_tpl
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

    # see Saint::ClassApi::Filter#query_string
    def query_string
      @setup.query_string
    end

    # see Saint::ClassApi::Filter#label
    def label
      @setup.label
    end

    private

    # get options for drop-down selector
    def drop_down_options

      return @type_values if @type_values
      return {} unless @setup.remote_model

      values, filters = Hash.new, Hash.new
      @setup.filters.each do |filter|
        static_filters, proc = filter
        filters.update(static_filters) if static_filters.is_a?(Hash)
        if proc && dynamic_filters = self.instance_exec(&proc)
          filters.update(dynamic_filters) if dynamic_filters.is_a?(Hash)
        end
      end
      @depends_on.select { |f, v| v }.each_pair do |f, v|
        puts
        p [f.var ,v ]
        puts
        v = [f.logic_prefix, v, f.logic_suffix].compact.join
        filters.update(f.remote_orm.send(f.logic, f.column, v))
      end

      # if current filter depends on some up filter,
      # and neither of up or current filter has an value,
      # build drop-down with empty options
      return {} if @setup.depends_on.size > 0 && filters.size == 0

      order = @setup.remote_orm.order(@setup.order)
      (@setup.remote_orm.filter(filters.merge(order))[0] || []).each do |remote_item|
        value = @setup.remote_columns.map do |c|
          val = Saint::Utils.column_format c, remote_item
          val.size > 0 ? val : nil
        end.compact.join(", ")
        values[remote_item.send(@setup.remote_pkey)] = value
      end
      values
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
