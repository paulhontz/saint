module Saint
  class ClassApi

    # set an belongs_to association.
    #
    # @example
    #    class Page
    #      saint.belongs_to :author, Author
    #    end
    # @param [Symbol] name
    # @param [Class] remote_model
    # @param [Proc] &proc configuration proc
    def belongs_to name = nil, remote_model = nil, &proc

      if name && remote_model

        # initializing association
        @belongs_to[name] = Assoc.new(__method__, name, @node, remote_model, &proc)

        # also trigger is_tree relations builder
        is_tree?
      end
      @belongs_to
    end

    # check if current node belongs_to given model
    # @param [Class] model
    def belongs_to? model
      (belongs_to || {}).select { |n, r| r.remote_model == model }.size > 0
    end

    # creates an has_n relation
    #
    # @example
    #    class Author
    #      saint.has_n :pages, Page
    #    end
    #
    # @example has_n through
    #    class Menu
    #      saint.has_n :pages, Page, MenuPages
    #    end
    #
    # @param [Symbol] name
    # @param [Class] remote_model
    # @param [Proc] &proc configuration proc
    def has_n name = nil, remote_model = nil, through_model = nil, &proc

      if name && remote_model

        # initializing relation
        @has_n[name] = Assoc.new(__method__, name, @node, remote_model, through_model, &proc)

        # also trigger is_tree relations builder
        is_tree?
      end
      @has_n
    end

    # is_tree creating 2 associations: :has_n and :belongs_to.
    # by default it is using #children for :has_n assoc and #parent for :belongs_to.
    # to override this, pass :has_n as 1st argument
    # and :belongs_to as second
    #
    # @example
    #   saint.is_tree( :childs, :root )
    #
    # by default, it will use :parent_id for both :local_key and :remote_key.
    # use #local_key/#remote_key in the proc to override this.
    # 
    # @example
    #    saint.is_tree( :childs, :root ) do
    #      local_key :pid
    #      remote_key :pid
    #    end
    # @param [Symbol] has_n
    # @param [Symbol] belongs_to
    # @param [Proc] &proc configuration proc
    def is_tree has_n = :children, belongs_to = :parent, &proc
      @associations[:is_tree] = [has_n, belongs_to, proc]
    end

    # (see #is_tree)
    def is_tree?

      return unless @associations[:is_tree]
      unless @is_tree

        @is_tree = Hash.new
        has_n, belongs_to, proc = @associations[:is_tree]
        node = @node

        assoc = Assoc.new(:has_n, has_n, @node, @node.saint.model) do
          node node
          local_key :parent_id
          remote_key :parent_id
          children has_n
          self.instance_exec(&proc) if proc
        end
        @has_n[has_n] = assoc
        @is_tree[:has_n] = assoc

        assoc = Assoc.new(:belongs_to, belongs_to, @node, @node.saint.model) do
          node node
          local_key :parent_id
          remote_key :parent_id
          parent belongs_to
          self.instance_exec(&proc) if proc
        end
        @belongs_to[belongs_to] = assoc
        @is_tree[:belongs_to] = assoc
      end
      @is_tree
    end

  end

  class Assoc

    include Saint::Inflector

    attr_reader :id,
                # "saint.has_n :authors" - has_n is type, :authors is name
                # "saint.belongs_to :author" - belongs_to is type, :author is name
                :type, :name,

                # displays assoc type and label
                :long_label,

                #@example
                #
                #class Authors
                #  saint.model Model::Author
                #end
                #class Pages
                #  saint.model Model::Page
                #  saint.belongs_to :author, Model::Author do
                #    remote_node Authors
                #  end
                #end
                #
                # :local_node is Pages
                # :local_model is  Model::Page
                # :local_orm is an ORM instance initialized for :local_model
                # remote_node is a method rather than an attribute, set to Authors on example above
                # :remote_model is Model::Author
                # :remote_orm is an ORM instance initialized for :remote_model
                :local_node, :local_model, :local_orm,
                :remote_model, :remote_orm,

                # @example
                #
                #class Pages
                #  saint.has_n :menus, Model::Menu, Model::MenuPage
                #end
                # 
                # :through_model is Model::MenuPage
                # :through_orm is an ORM instance initialized for :through_model
                :through_model, :through_orm,

                # if this is set to true, Saint will create an "Create New" button
                # when rendering association UI.
                # it can be set to true when defining remote_node.
                # simply set second argument to true:
                #
                #saint.has_n :pages, Model::Page do
                #  remote_node Pages, true
                #end
                :remote_node_create_button

    # initialize new association
    #
    # @param [Symbol] type :has_n or :belongs_to
    # @param [Symbol] name
    # @param [Class] node
    # @param [Class] remote_model
    # @param [Class] through_model defaulted to nil
    # @param [Proc] &proc
    def initialize type, name, node, remote_model, through_model = nil, &proc

      @type, @local_node, @name = type, node, name
      @remote_model, @through_model = remote_model, through_model

      unless @local_model = @local_node.saint.model
        raise "saint.#{@type} error: Please define saint.model before dealing with saint.#{@type}"
      end

      unless @local_model.respond_to?(:new)
        raise "saint.#{@type} error: #{@local_model} class should respond to #new"
      end

      unless @local_model.new.respond_to?(@name)
        raise "saint.#{@type} error: #{@local_model} instance should respond to ##{@name}"
      end

      @label = @name.to_s.capitalize
      @long_label = [@type.to_s, @label].join(' ')

      @ipp = 10
      @filters = Array.new
      @columns = Hash.new

      @local_pkey = @local_node.saint.pkey
      @remote_pkey = :id

      self.instance_exec(&proc) if proc

      @local_orm = Saint::ORM.new @local_model, @local_node
      @remote_orm = Saint::ORM.new @remote_model, @remote_node
      if @through_model
        @through_orm = Saint::ORM.new @through_model, @local_node, @remote_node
      end

      if @type == :has_n

        local_table = local_orm.storage_name

        if @through_model
          remote_table = @remote_orm.storage_name
          @local_key ||= (singularize(local_table) + "_id").to_sym
          @remote_key ||= (singularize(remote_table) + "_id").to_sym
        else
          @local_key ||= :id
          @remote_key ||= (singularize(local_table) + "_id").to_sym
        end
      else
        @local_key ||= foreign_key(name)
        @remote_key ||= :id
      end

      @id = [@type, @name, @local_node, @local_model, @remote_node].
          map { |c| c.to_s }.join('_').gsub(/[^\w|\d]/, '_').gsub(/_+/, '_')

      ::Saint.relations[@id] = self
    end

    # by default, UI will display all columns for remote items.
    # use #column to define custom columns to be displayed.
    # the syntax is same as when using saint.column
    #
    # @example use only :title when displaying remote items
    #    saint.has_h :pages, Page do
    #      column :title
    #    end
    #
    # see {Saint::ClassApi#column}
    def column name, type = nil, &proc
      @default_columns = nil
      column = ::Saint::SaintColumn.new(name, type, &proc)
      @columns[column.name] = column
    end

    # returns earlier defined columns.
    # if none defined, returns 3 remote columns if remote node given,
    # or first non-id remote column otherwise.
    def columns

      return @columns if @columns.size > 0

      # no columns defined for current assoc

      if @remote_node
        # remote_node defined, using 3 remote columns
        remote_columns = @remote_node.saint.columns
        remote_columns.select { |k, v| remote_columns.keys[0..2].include?(k) }.each_value do |column|
          @columns[column.name] = column
        end
      end
      if @columns.size == 0
        # seems remote node not defined, using 1st non-id remote column
        if column = @remote_orm.properties(true).first
          column = ::Saint::SaintColumn.new(column)
          @columns[column.name] = column
        end
      end
      @columns
    end

    # is current association an has_n relation?
    def has_n?
      type == :has_n
    end

    # is current association an belongs_to relation?
    def belongs_to?
      type == :belongs_to
    end

    # by default, only remote model required for an assoc to work.
    # however, if remote model is managed by Saint as well,
    # you can set it and UI will add links to remote item,
    # as well as buttons to create new remote items.
    #
    # @example
    #    class Controller::Pages
    #      include Saint::Api
    #      saint.model Page
    #    end
    #
    #    class Controller::Author
    #      saint.has_n :pages, Page do
    #        remote_node Controller::Pages
    #      end
    #    end
    # @param [Class] node
    # @param [Boolean] create_button
    #   if set to a positive value, GUI will display "Create New" button
    #   that will open an dialog where a new remote item can be created.
    def remote_node node = nil, create_button = false
      if node
        @remote_node = node
        @remote_node_create_button = create_button
      end
      @remote_node
    end

    alias :node :remote_node

    # the column on local model that should match the pkey of remote model.
    #
    # @example
    #    # scenario:
    #    #   relation: belongs_to
    #    #   local model: Model::City
    #    #   remote model: Model::Country
    #    class City
    #      saint.model Model::City
    #      saint.belongs_to :country, Model::Country
    #    end
    #    # this assoc expects Model::City to respond to #country_id,
    #    # as Model::City#country_id will be compared to Model::Country#id
    #    # using #local_key to override this:
    #    class City
    #      saint.model Model::City
    #      saint.belongs_to :country, Model::Country do
    #        local_key :cntr_id
    #      end
    #    end
    #    # now Model::City#cntr_id will be compared to Model::Country#id
    #
    # on has_n_through relations, local key is defaulted to name of local model suffixed by _id
    #
    # @example
    #    # scenario:
    #    #   relation: has_n_through
    #    #   local model: Model::Page
    #    #   remote model: Model::Menu
    #    class Page
    #      saint.model Model::Page
    #      saint.has_n :menus, Model::Menu, Model::MenuPage
    #    end
    #    # this assoc expects Model::MenuPage to respond to #page_id,
    #    # as Model::Page#id will be compared to Model::MenuPage#page_id
    #    # using #local_key to override this:
    #    class Page
    #      saint.model Model::Page
    #      saint.has_n :menus, Model::Menu, Model::MenuPage do
    #        local_key :pid
    #      end
    #    end
    #    # now Model::Page#id will be compared to Model::MenuPage#pid
    #
    # @param [Symbol] key `:id`
    def local_key key = nil
      @local_key = key if key
      @local_key
    end

    # the column on remote model that should match the pkey of local model
    #
    # @example
    #    # scenario:
    #    #   relation: has_n
    #    #   local model: Model::Author
    #    #   remote model: Model::Page
    #    class Author
    #      saint.model Model::Author
    #      saint.has_n :pages, Model::Page
    #    end
    #    # this assoc expects Model::Page to respond to :author_id,
    #    # as Model::Author#id will be compared to Model::Page#author_id
    #    # using #remote_key to override this:
    #    class Author
    #      saint.model Model::Author
    #      saint.has_n :pages, Model::Page do
    #        remote_key :auid
    #      end
    #    end
    #    # now Model::Author#id will be compared to Model::Page#auid
    #
    # on has_n_through relations, remote key is defaulted to name of remote model suffixed by _id
    #
    # @example
    #    # scenario:
    #    #   relation: has_n_through
    #    #   local model: Model::Page
    #    #   remote model: Model::Menu
    #    class Page
    #      saint.model Model::Page
    #      saint.has_n :menus, Model::Menu, Model::MenuPage
    #    end
    #    # this assoc expects Model::MenuPage to respond to #menu_id,
    #    # as Model::Menu#id will be compared to Model::MenuPage#menu_id
    #    # using #local_key to override this:
    #    class Page
    #      saint.model Model::Page
    #      saint.has_n :menus, Model::Menu, Model::MenuPage do
    #        remote_key :mid
    #      end
    #    end
    #    # now Model::Menu#id will be compared to Model::MenuPage#mid
    #
    # @param [Symbol] key `:id`
    def remote_key key = nil
      @remote_key = key if key
      @remote_key
    end

    # primary key for local model,
    # readonly, extracted from saint.pkey
    def local_pkey *args
      if args.size > 0
        warn 'Please do not define local_pkey inside relations. Use saint.pkey instead.'
      end
      @local_pkey
    end

    # primary key for remote model, defaulted to :id.
    # remote items will be searched using this key.
    #
    # @example set :pid as primary key for Model::Page
    #    class Author
    #      saint.has_n :pages, Model::Page do
    #        remote_pkey :pid
    #      end
    #    end
    #
    # @param [Symbol] key `:id`
    def remote_pkey key = nil
      @remote_pkey = key if key
      @remote_pkey || (@remote_node.saint.pkey if @remote_node)
    end

    # filter remote items.
    #
    # for static filters, simply pass a hash.
    #
    # for dynamic filters, pass a proc.
    # proc will receive back the current local item,
    # so you can create a hash using its data.
    #
    # to combine static and dynamic filters, pass both a hash as argument and a proc.
    # if static and dynamic filters has same keys,
    # dynamic filters will override the static ones.
    #
    # @example static filters - display only active authors:
    #
    #    class Page
    #      saint.belongs_to :author, Model::Author do
    #        filter active: 1
    #      end
    #    end
    #
    # @example dynamic filters - display only teams of same region as current game:
    #    class Game
    #      saint.belongs_to :team, Model::Team do
    #        filter do |game|
    #          {region_id: game.edition.competition.region_id}
    #        end
    #      end
    #    end
    #
    def filter filters = {}, &proc
      @filters << [filters, proc]
    end

    # prepare and return earlier defined filters
    def filters row = nil
      @filters.inject({}) do |filters, filter|
        static_filters, proc = filter
        filters.merge(static_filters) if static_filters.is_a?(Hash)
        if (filter = proc.call(row) rescue nil).is_a?(Hash)
          filters.merge filter
        end
      end
    end

    # the order to be used when displaying items.
    # by default, if remote node defined, it will use there order,
    # otherwise, it will arrange items by remote pkey in descending order.
    # use this method to set custom order.
    # call it multiple times to order by multiple columns/directions.
    #
    # @example order pages by date, newer first
    #    class Author
    #      saint.has_n :pages, Page do
    #        order :date, :desc
    #      end
    #    end
    #
    # @param [Symbol] column
    # @param [Symbol] direction, :asc or :desc
    def order column = nil, direction = :asc
      if column
        raise "Column should be a Symbol,
          #{column.class} given" unless column.is_a?(Symbol)
        raise "Unknown direction #{direction}.
          Should be one of :asc, :desc" unless [:asc, :desc].include?(direction)
        (@order ||= Hash.new)[column] = direction
      end
      @order || (remote_node.saint.order if remote_node) || {remote_pkey => :desc}
    end

    # self-explanatory
    def items_per_page items = nil
      @ipp = items if items
      @ipp
    end

    alias :ipp :items_per_page

    # set custom label for current association
    #
    # @example "Pages" label used, derived from assoc name
    #    class Author
    #      saint.has_n :pages, Page do
    #        order :date, :desc
    #      end
    #    end
    #
    # @example set custom label
    #    class Author
    #      saint.has_n :pages, Page do
    #        label 'Published Pages'
    #      end
    #    end
    def label label = nil
      @label = label if label
      @label
    end

    # if set to true, assoc UI will prohibit to attach/detach remote items.
    def readonly is_true = nil
      @readonly = true if is_true
      @readonly
    end

    # methods used internally by is_tree relations
    begin
      def children meth = nil
        if meth
          @children = meth
          @is_tree = true
        end
        @children
      end

      def parent meth = nil
        if meth
          @parent = meth
          @is_tree = true
        end
        @parent
      end

      def is_tree?
        @is_tree
      end
    end

    # callbacks to be executed before/after updating the relation.
    # callbacks will be executed inside the class that defined current association
    begin
      def before &proc
        @before = proc if proc
        @before
      end

      def after &proc
        @after = proc if proc
        @after
      end
    end

  end
end
