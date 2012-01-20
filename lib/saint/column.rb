module Saint
  class SaintColumn

    OPTS = [
        # if set to true, item wont be saved if field is empty.
        :required,

        # :multiple allow to select multiple options on drop-down selectors.
        # :size indicates how much lines to display for select-multiple columns.
        :multiple, :size,

        # string used to join values for checkbox and select-multiple columns.
        # by default a coma will be used.
        :join_with,

        # options to be used on select, radio and checkbox selectors.
        :options,

        # set value to be used when value for given column is nil.
        # for selectable columns, default option will be auto-selected,
        # on text columns, default text will be displayed.
        :default,

        # By default, Saint will use capitalized name for label:
        #
        #   saint.column :name
        #   # HTML: <fieldset><legend>Name</legend>...
        #
        # To have an custom label, use :label option:
        #
        #   saint.column :name, label: "Author's Name"
        #   # HTML: <fieldset><legend>Author's Name</legend>...
        :label,

        # search/group columns by tags
        :tag,

        # make current column a part of a grid
        :grid,

        # set width/height for used grid
        :grid_width, :grid_height,

        # css
        :width, :height, :css_style, :css_class,

        # use a custom layout for current column.
        # also see {Saint::ClassApi#column_layout}, which set layout for all columns
        :layout,

        # use default layout but add this css style
        :layout_style,

        # use default layout but add this css class
        :layout_class
    ]
    OPTS.each { |o| attr_reader o }

    attr_reader :id, :name, :type, :proc, :summary, :crud, :save

    def initialize node_or_node_instance, name, opts = {}

      if node_or_node_instance.instance_of?(::Saint::InstanceApi)
        @node, @node_instance = node_or_node_instance.class, node_or_node_instance
      else
        @node, @node_instance = node_or_node_instance, nil
      end

      @proc = opts[:proc]
      @id = '%s_%s' % [name, Digest::MD5.hexdigest(@proc.to_s)]
      @name = name.to_sym

      # default type is string
      @type = opts.fetch :type, :string

      # should the column be shown on Summary pages? true by default
      @summary = opts.fetch :summary, true
      # should the column be shown on Crud pages? true by default
      @crud = opts.fetch :crud, true
      # should the column used when object persisted to db? true by default
      @save = opts.fetch :save, true
      # plain columns not saved to db
      @save = false if plain?

      OPTS.each { |v| self.instance_variable_set(:"@#{v}", opts[v]) }

      if @options
        if @options.is_a?(Array)
          @options = Hash[@options.zip(@options.map { |o| Saint::Inflector.titleize(o) })]
        else
          raise('options should be either an Hash or an Array') unless @options.is_a?(Hash)
        end
      end

      @label ||= Saint::Inflector.titleize(@name)

      width = @width ?
          (@width.is_a?(Numeric) ? '%spx' % @width : @width) :
          select? || password? ? nil : '100%'
      @css_style = "#{@css_style} #{ "width: #{width};" if width } #{"height: #{@height};" if @height}"
    end

    def join_with
      @join_with || ','
    end

    def required?
      @required
    end

    def select?
      @type == :select
    end

    def checkbox?
      @type == :checkbox
    end

    def plain?
      @type == :plain
    end

    def boolean?
      @type == :boolean
    end

    def password?
      @type == :password
    end
    
    def rte?
      @type == :rte
    end

    class ScopeHelper

      attr_reader :name

      def initialize name
        @name = name.to_sym
      end

      def summary?
        @name == :summary
      end

      def crud?
        @name == :crud
      end

      def == v
        v == @name
      end
    end

    # alias for `value row, :crud'
    def crud_value row
      value row, :crud
    end

    # alias for `value row, :summary'
    def summary_value row
      value row, :summary
    end

    # extract, modify if needed and return value for current column
    #
    # @param [Object] row
    # @param [Symbol] scope
    def value row, scope

      value = row[@name]
      scope = ScopeHelper.new scope

      if boolean? && scope.summary?
        value = Saint::Utils::BOOLEAN_OPTIONS[value]
      end

      if @proc && val = (@node_instance || @node).instance_exec(value, scope, row, &@proc)
        value = val
      end

      # passwords are not wrapped
      return value if password?

      # if rb_wrapper is enabled for current node, wrap value accordingly.
      # it will be unwrapped when saved to db.
      if rb_wrapper = @node.saint.rbw
        value = rb_wrapper.wrap(value)
      end
      value
    end

  end
end
