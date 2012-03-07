module Saint
  class ClassApi

    def subset column, filters
      if filters.is_a?(Hash)
        @subsets[column] = filters.inject({}) { |f, c| f.update c[0].to_s.gsub(/[^\w|\d|\-|\.]/i, '') => c }
        @filters.delete column
      end
    end

    def subset_instances params, *types
      instances = @subsets.map { |c, f| Subset.new(@node, c, f, params) }
      types = (types.size == 0 ? [:orm, :http, :html] : types).compact
      filters = types.map do |type|
        case type
          when :orm
            instances.map { |i| i.send type }.inject({}) { |f, c| f.update c }
          else
            instances.map { |i| i.send type }
        end
      end
      filters.size == 1 ? filters.first : filters
    end

    class Subset

      include Saint::Utils
      VAR = 'saint-subsets'

      def initialize node, column, filters, params = {}
        @node, @params = node, params
        @column, @filters = column, filters
        if @params[VAR].is_a?(Hash) && active_filter = @params[VAR][column.to_s]
          @filters.each_key { |f| @active_filter = f if f == active_filter }
        end
      end

      def orm
        @active_filter ? {@column => @filters[@active_filter].last} : {}
      end

      def http
        @active_filter ? '%s=%s' % [query_string, @active_filter] : []
      end

      def html
        @filters.map do |filter, setup|
          {
              name: query_string,
              value: filter,
              label: setup.first,
              active: filter == @active_filter
          }
        end
      end

      private
      def query_string
        '%s[%s]' % [VAR, @column]
      end

    end

  end
end
