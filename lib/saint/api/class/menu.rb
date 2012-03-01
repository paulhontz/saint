module Saint
  class ClassApi

    # initializing and/or returning menu Api(see {Saint::ClassApi::MenuApi})
    def menu &proc
      @menu ||= MenuApi.new(@node, &proc)
      @menu
    end

  end

  class MenuApi

    attr_reader :node,
                :label,
                :parent,
                :children,
                :position,
                :prefix, :suffix

    def initialize node = nil, &proc

      @node = node
      @scope = :default
      @position = 0
      @children = Array.new
      self.instance_exec(&proc) if proc
    end

    def url url = nil
      @url = url if url
      @url || (@node.http.route if @node)
    end

    # label to be displayed in UI
    def label label = nil
      @label = label if label
      @label || (@node.saint.label if @node)
    end

    # node under which the current menu item will reside
    def parent parent = nil
      return @parent unless parent
      @parent = parent.respond_to?(:saint) ? parent.saint.menu : parent
      @parent.children << self
    end

    # positioning menu items, higher first
    def position position = nil
      @position = position if position
      @position
    end

    # string to put before label
    def prefix str = nil
      @prefix = str if str
      @prefix
    end

    # string to put after label
    def suffix str = nil
      @suffix = str if str
      @suffix
    end

    # only display label, without link it to any page
    def void *args
      @void = true
    end

    # (see #void)
    def void?
      @void
    end

    # some nodes should not be displayed in menu
    def disabled *args
      @disabled = true
    end

    # (see #disabled)
    def disabled?
      @disabled
    end

  end

end
