module Saint
  class ClassApi

    # given model may contain many columns,
    # however, in most cases, not all of them should be managed by Saint.
    #
    # @example display :name in both Summary and CRUD pages. type defaulted to String
    #    saint.column :name
    #
    # @example show the :date only on CRUD pages
    #    saint.column :date do
    #      summary false
    #    end
    #
    # @example drop-down selector
    #    saint.column :color, :select do
    #      options ['red', 'green', 'blue']
    #    end
    #
    # @example display date in human format on summary pages
    #    saint.column :date do
    #      value do |val|
    #        val.strftime('%b %d, %Y') if summary?
    #      end
    #    end
    #
    # @example display name with email on summary pages
    #    saint.column :name do
    #      value do |val|
    #        '%s <%s>' % [val, row.email] if summary?
    #      end
    #    end
    #
    # @param [Symbol] name
    # @param [Symbol] type
    # @param [Proc] &proc
    def column name, type = nil, &proc
      return unless configurable?
      @grid && @grid_columns += 1
      column = SaintColumn.new(name, type, rbw: @node.saint.rbw, grid: @grid, &proc)
      columns[column.name] = column
    end

    # by default, GUI use a fieldset to display elements.
    # use this method to define a custom layout.
    #
    # @example set custom layout for all elements
    #
    #    # default layout for an text element looks like:
    #    # <fieldset><legend>[label]</legend>[field]</fieldset>
    #    # use saint.column_layout to set custom layout
    #
    #    saint.column_layout '<div>[label]: [field]</div>'
    #
    # @param [String] layout
    #   should contain [label] and [field] snippets
    def column_layout layout = nil
      @column_layout = layout if configurable? && layout
      @column_layout
    end

    # returns the columns defined earlier
    def columns
      @columns ||= Hash.new
    end

    # by default, columns are delimited by line break.
    # this method allow to puts many columns on same line.
    #
    # @example
    #    saint.grid do
    #      column :name
    #      column :age
    #    end
    #
    # @example
    #    saint.grid header: 'some html' do
    #      column :name
    #      column :age
    #      column :email
    #    end
    #
    def grid *name_and_or_opts, &proc
      return unless configurable?
      name, opts = nil, Hash.new
      name_and_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : name = a }
      id = Digest::MD5.hexdigest(name.to_s + proc.to_s)
      name ||= id
      if proc
        @grid, @grid_columns = name, 0
        self.instance_exec &proc
        @grid = nil
      end
      columns = opts.delete(:columns) || @grid_columns || 2
      grids[name] = Struct.new(:id, :name, :columns, :opts).new(id, name, columns, opts)
    end

    # returns earlier defined grids
    def grids
      @grids ||= Hash.new
    end

  end

end
