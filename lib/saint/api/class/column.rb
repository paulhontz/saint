module Saint
  class ClassApi

    # given model may contain many columns,
    # however, in most cases, not all of them should be displayed in GUI.
    # this method allow to add columns one by one, with opts and callback.
    #
    # this method also accepts an proc.
    # proc meaning is to modify given value, depending on given scope,
    # and return modified version.
    # 
    # if proc returns nil, original value will be used.
    # 
    # given block will receives back 3 arguments:
    # *  value
    # *  scope, one of
    #    -  :summary, used when data displayed on summary pages.
    #    -  :crud, used when data displayed on crud pages.
    # *  row, currently handled row, so you can mix the value of current column with values of other columns.
    #
    # block is executed inside currently running controller,
    # so it have access to any of #http, #view, #admin Api methods.
    #
    # @example display :name in both Summary and CRUD pages, type defaulted to String
    #    saint.column :name
    #
    # @example show the :date only on CRUD pages
    #    saint.column :date, summary: false
    #
    # @example display date in human format on summary pages
    #    saint.column :date do |val, scope|
    #      val.strftime('%b %d, %Y') if scope.summary?
    #    end
    #
    # @example display name with email on summary pages
    #    saint.column :name do |val, scope, row|
    #      '%s <%s>' % [val, row.email] if scope.summary?
    #    end
    #
    # @param [Symbol] name
    # @param [Hash] opts
    # @param [Proc] &proc
    def column name, opts = {}, &proc
      return unless configurable?
      opts[:proc] = proc
      if opts[:grid] = @grid
        @grid_columns += 1
      end
      columns[name] = opts
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
