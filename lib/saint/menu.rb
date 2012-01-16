module Saint
  class Menu

    attr_reader :scope

    def initialize scope = :default
      @scope = scope
    end

    def render

      @view_api = Presto::View::Api.new
      @view_api.engine Saint.view.engine
      @view_api.root '%s/menu/' % Saint.view.root
      @view_api.scope self

      @layout = '%s/layout.%s' % [@view_api.root, Saint.view.ext]
      @template = '%s/menu.%s' % [@view_api.root, Saint.view.ext]

      @nodes, tmp = Array.new, Hash.new
      Presto.nodes.select { |n| n.respond_to?(:saint) }.each do |node|
        next if node.saint.menu.disabled?
        next unless node.saint.menu.label
        tmp[node] = node.saint.menu.position
      end
      tmp.sort { |a, b| b[1] <=> a[1] }.each { |n| @nodes << n[0] }

      @tree = build @scope
      @view_api.render_view @layout
    end

    private
    def build scope, parent = nil
      html = ""
      @nodes.each do |node|
        next unless @menu = node.saint.menu
        next unless @menu.label
        next unless @menu.scope == scope
        next unless @menu.parent == parent
        html << @view_api.render_partial(@template)
      end
      html
    end

  end
end
