module Saint
  class SaintColumn

    attr_reader :id, :name, :type, :grid
    attr_reader :row, :scope

    def initialize name, type = nil, opts = {}, &proc

      # by default, all columns are shown on all pages and saved to db.
      @summary = true
      @crud = true
      @save = true

      proc && self.instance_exec(&proc)

      # default type is string
      @type = type || :string

      # use rb_wrapper only if it is required
      @rbw = opts.fetch :rbw, false

      # is current column a part of a grid
      @grid = opts.fetch :grid, nil

      @id = '%s_%s' % [name, Digest::MD5.hexdigest(@proc.to_s)]
      @name = name.to_sym

      @label ||= Saint::Inflector.titleize(@name)

      width = @width ?
          (@width.is_a?(Numeric) ? '%spx' % @width : @width) :
          select? || password? ? nil : '100%'
      height = @height ?
          (@height.is_a?(Numeric) ? '%spx' % @height : @height) :
          nil
      @css_style = '%s %s %s' % [
          @css_style,
          ("width: %s;" % width if width),
          ("height: %s;" % height if height)
      ]
    end

    # should the column be shown on Summary pages?
    # true by default
    def summary *args
      @summary = args.first if args.size > 0
    end

    # true when column shown on Summary pages
    def summary?
      @scope ? @scope == :summary : @summary
    end

    # should the column be shown on Crud pages?
    # true by default
    def crud *args
      @crud = args.first if args.size > 0
    end

    # true when column shown on CRUD pages
    def crud?
      @scope ? @scope == :crud : @crud
    end

    # should the column be used when object persisted to db?
    # true by default
    def save *args
      @save = args.first if args.size > 0
    end

    def save?
      plain? ? false : @save
    end

    # if set to true, item wont be saved if field is empty.
    # false by default
    def required *args
      @required = args.first if args.size > 0
    end

    def required?
      @required
    end

    # should the select-multiple drop-downs allow multiple options selection?
    # false by default
    def multiple *args
      @multiple = args.first if args.size > 0
      @multiple
    end

    # indicates how much lines to display for select-multiple columns.
    # nil by default
    def size size = nil
      @size = size.to_i if size
      @size
    end

    # string used to join values for checkbox and select-multiple columns.
    # a coma will be used by default
    def join_with str = nil
      @join_with = str if str
      @join_with || ', '
    end

    # options to be used on select, radio and checkbox selectors
    def options options = nil
      if options
        if options.is_a?(Array)
          options = Hash[options.zip(options.map { |o| Saint::Inflector.titleize(o) })]
        else
          raise('options should be either an Hash or an Array') unless options.is_a?(Hash)
        end
        @options = options
      end
      @options
    end

    # set value to be used when value for given column is nil.
    # for selectable columns, default option will be auto-selected,
    # on text columns, default text will be displayed.
    def default value = nil
      @default = value if value
      @default
    end

    # By default, Saint will use capitalized name for label:
    #
    #    saint.column :name
    #    # HTML: <fieldset><legend>Name</legend>...
    #
    # To have an custom label, use #label inside block:
    #
    #    saint.column :name do
    #      label "Author's Name"
    #    end
    #    # HTML: <fieldset><legend>Author's Name</legend>...
    def label label = nil
      @label = label if label
      @label
    end

    # search/group columns by tags
    def tag tag = nil
      @tag = tag if tag
      @tag
    end

    # set width/height for used grid
    def grid_width val = nil
      @grid_width = val if val
      @grid_width
    end

    def grid_height val = nil
      @grid_height = val if val
      @grid_height
    end

    # css
    def width val = nil
      @width = val if val
      @width
    end

    def height val = nil
      @height = val if val
      @height
    end

    def css_style val = nil
      @css_style = val if val
      @css_style
    end

    def css_class val = nil
      @css_class = val if val
      @css_class
    end

    # use a custom layout for current column.
    # also see {Saint::ClassApi#column_layout}, which set layout for all columns
    def layout val = nil
      @layout = val if val
      @layout
    end

    # use default layout but add this css style
    def layout_style val = nil
      @layout_style = val if val
      @layout_style
    end

    # use default layout but add this css class
    def layout_class val = nil
      @layout_class = val if val
      @layout_class
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

    # alias for `value row, :crud'
    def crud_value row
      value row, :crud
    end

    # alias for `value row, :summary'
    def summary_value row
      value row, :summary
    end

    private
    # if block given, this method will set a proc to be executed when column value requested.
    # proc meaning is to modify given value, depending on given scope, and return modified version.
    # if proc returns nil, original value will be used.
    #
    # given block will receive an single argument - current value.
    # block should modify value, if needed, and return it.
    # given block will have access to following helper methods:
    # *  #summary? - true if column is currently shown on Summary pages
    # *  #crud? - true if column is currently shown on CRUD pages
    # *  #row - current row object
    # *  #scope - one of :summary or :crud
    #
    # block is executed inside currently running controller,
    # so it have access to any of #http, #view, #admin Api methods.
    #
    # if row and scope given, this method will extract, modify if needed,
    # and return value for current column
    #
    # @param [Object] row
    # @param [Symbol] scope
    # @param [Proc] proc
    def value row = nil, scope = nil, &proc

      if proc
        return @value_proc = proc
      else
        raise ArgumentError unless row && scope
      end

      # extracting value
      value = row[@name]

      @row, @scope = row, scope
      
      if @options && summary?
        value = @options[value]
      end

      if boolean? && summary?
        value = Saint::Utils::BOOLEAN_OPTIONS[value]
      end

      if @value_proc && val = self.instance_exec(value, &@value_proc)
        value = val
      end
      @row, @scope = nil, nil

      # passwords are not wrapped
      return value if password?

      @rbw && value = @rbw.wrap(value)
      value
    end


  end
end
