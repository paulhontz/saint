require '../../presto/lib/presto' unless Object.const_defined?(:Presto)
require 'cgi/util'
require 'digest'
require 'erubis'
require 'json'
require 'mini_magick'
require 'find'
require 'base64'

module Saint

  class << self

    include Presto::Utils
    include Presto::View::Utils

    attr_accessor :menu, :relations, :nodes

    def root
      @root ||= ::File.join(::File.expand_path('../saint', __FILE__), '')
    end

    def ordered_nodes
      nodes.select { |n| n.saint.menu.label unless n.saint.menu.disabled? }.
          sort { |a, b| [b.saint.menu.position, a.saint.label] <=> [a.saint.menu.position, b.saint.label] }
    end

    def orm orm = nil
      @orm = orm if orm
      @orm
    end

    def items_per_page n = nil
      @ipp = n if n
      @ipp
    end

    alias :ipp :items_per_page

    def tree_colors *colors
      @tree_colors = colors if colors.size > 0
      @tree_colors
    end

    def view
      @view ||= Struct.new(:root, :engine, :ext).new(::File.join(root, 'view/'), :Erubis, 'erb')
    end

  end
  self.relations, self.nodes = Hash.new, Array.new
end

module SaintConst
  NULL_VALUE = '__Saint::ReservedConstants.null_value__'
end

Saint.items_per_page 25
Saint.tree_colors 'FFF8DC', 'FFEBCD', 'FAF0E6', 'FAEBD7', 'F5F5F5',
                  'F5F5DC', 'FFFFF0', 'FFF5EE', 'FFFAF0'

%w[
utils.rb
inflector/**/*rb
extender/**/*rb
api/**/*rb
*rb
].each do |s|
  Dir[Saint.root + s].each { |f| require f }
end
