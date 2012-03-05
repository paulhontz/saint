module Saint
  class CrudExtender

    def filter
      @node.class_exec do

        def filter column, seed
          return unless filter = self.class.saint.get_filters.values.select do |f|
            f.column == column.to_sym
          end.first
          instance = Saint::FilterInstance.new filter, http.params, seed
          instance.send(:html, true)
        end

      end
    end
  end
end
