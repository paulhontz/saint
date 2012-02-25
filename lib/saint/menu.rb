module Saint
  class Menu

    include Saint::Utils

    # initialize new menu builder.
    #
    # @param [Boolean] pristine do not include items defined in controllers
    # @param [Proc] &proc
    def initialize pristine = false, &proc
      @parent = nil
      @pristine = pristine
      @opted_items = Array.new
      self.instance_exec(&proc) if proc
    end

    # add new item to menu.
    #
    # @example adding link to Page controller
    #    menu = Saint::Menu.new
    #    menu.item 'Pages', Ctrl::Page
    #    menu.render
    #
    # @example nested menus
    #    menu = Saint::Menu.new
    #    menu.item 'SomeLink', '/some/url', position: -100 do
    #      item 'SomeSubLink', '/some/another/url' do
    #        item 'SomeSubSubLink', '/yet/some/url'
    #      end
    #    end
    #    menu.render
    #
    # @param [String] anchor
    # @param [Array] *link_and_or_opts
    # @options link_and_or_opts [prefix] :prefix
    # @options link_and_or_opts [suffix] :suffix
    # @options link_and_or_opts [void] :void
    # @param [Proc] &proc
    def item anchor, *link_and_or_opts, &proc
      link, opts = nil, Hash.new
      link_and_or_opts.each { |a| a.is_a?(Hash) ? opts.update(a) : link = a }
      @menu = MenuApi.new do
        label anchor
        url link.respond_to?(:http) ? link.http.route : link
        prefix opts[:prefix] if opts.has_key?(:prefix)
        suffix opts[:suffix] if opts.has_key?(:suffix)
        void opts[:void] if opts.has_key?(:void)
      end
      @opted_items << @menu
      @menu.parent @parent

      @parent = @menu
      self.instance_exec(&proc) if proc
      @parent = nil

      @menu
    end

    # set parent for current item.
    #
    # @example set parent to some predefined Saint controller
    #    menu = Saint::Menu.new
    #    menu.item 'SomeLink', '/some/url' do
    #      parent Some::Controller
    #    end
    #    menu.render
    #
    # @param [Class] parent
    def parent parent
      @menu.parent parent
    end

    def render opts = {}
      opts[:class] = 'sf-menu' unless opts.has_key?(:class)
      saint_view.render_view 'menu/layout', opts: opts
    end

    private

    def items
      @pristine ?
          @opted_items :
          Saint.ordered_nodes.map { |n| n.saint.menu }.compact + @opted_items
    end

    def tree parent = nil
      html = ''
      items.select { |i| i.label && i.parent == parent }.each do |item|
        html << saint_view.render_partial('menu/menu', item: item)
      end
      html
    end

  end
end
