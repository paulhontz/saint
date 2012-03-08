module Saint
  class ClassApi

    # set the order to be used when items extracted.
    # by default, Saint will arrange items by primary key, in descending order.
    # this method is aimed to override default order.
    # call it multiple times to order by multiple columns/directions.
    #
    # @example
    #    saint.order :date, :desc
    #    saint.order :name, :asc
    #
    # @param [Symbol] column
    # @param [Symbol] direction, `:asc`, `:desc`
    def order column = nil, direction = :asc
      if column && configurable?
        raise "Column should be a Symbol,
          #{column.class} given" unless column.is_a?(Symbol)
        raise "Unknown direction #{direction}.
          Should be one of :asc, :desc" unless [:asc, :desc].include?(direction)
        (@order ||= Hash.new)[column] = direction
      end
      @order || {pkey => :desc}
    end

    class Ordered

      module Mixin
        def extract params = {}
          self.new(params).extract
        end

        def orm params = {}
          self.new(params).orm
        end

        def http params = {}
          self.new(params).http
        end

        def column_var
          'saint-order-column'
        end

        def vector_var
          'saint-order-vector'
        end

        def vectors
          ['asc', 'desc']
        end
      end

      extend Mixin
      include Mixin

      def initialize params = {}
        @params = params
      end

      def extract
        @params.values_at(column_var, vector_var).select { |v| v.is_a?(String) && v.size > 0 }
      end

      def orm
        c, v = extract
        c && v && {c.to_sym => v.to_sym}
      end

      def http
        filters = []
        c, v = extract
        c && filters << '%s=%s' % [column_var, c]
        v && filters << '%s=%s' % [vector_var, v]
        filters
      end

    end

  end
end
