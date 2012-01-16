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
                :scope,
                :position,
                :prefix, :suffix

    def initialize node, &proc
      @node = node
      @scope = :default
      @position = 0
      @children = Array.new
      self.instance_exec(&proc) if proc
    end

    # label to be displayed in GUI
    def label label = nil
      @label = label if label
      @label || @node.saint.h
    end

    # node under which the current menu item will reside
    def parent parent = nil
      return @parent unless parent
      @parent = parent
      @parent.saint.menu.children << @node
    end

    # allow to have multiple menus, by putting various nodes in various menu scopes.
    def scope scope = nil
      @scope = scope if scope
      @scope
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
