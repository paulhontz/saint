require 'presto' unless Object.const_defined?(:Presto)
require 'digest'
require 'erubis'
require 'json'
require 'mini_magick'

module Saint

  RV_NULL_VALUE = '::Saint::ReservedVariables.__null_value__'
  RV_META_TITLE = '::Saint::ReservedVariables.__meta_title__'

  class << self

    include Presto::InternalUtils
    include Presto::View::InternalUtils

    attr_accessor :menu, :relations

    def root
      @root ||= ::File.expand_path('saint', ::File.dirname(__FILE__)) + '/'
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
      @view ||= Struct.new(:root, :engine, :ext).new('%s/view/' % root, :Erubis, :erb)
    end

  end
  self.relations = Hash.new
end

Saint.items_per_page 10
Saint.tree_colors 'FFF8DC', 'FFEBCD', 'FAF0E6', 'FAEBD7', 'F5F5F5',
                  'F5F5DC', 'FFFFF0', 'FFF5EE', 'FFFAF0'

%w[
inflector/**/*rb
utils/**/*rb
extender/**/*rb
api/**/*rb
*rb
].each do |s|
  Dir[Saint.root + s].each { |f| require f }
end
