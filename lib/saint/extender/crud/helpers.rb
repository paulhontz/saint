module Saint
  class CrudExtender

    def helpers
      @node.class_exec do

        private

        def render_columns columns, scope, row
          columns.select { |n, c| c.send scope }.values.inject({}) do |map, column|
            @element, @row_val = column, column.value(row, scope)
            html = column.type ? saint_view.render_partial('edit/elements/%s' % column.type) : @row_val
            map.update(column => html)
          end
        end

        def render_elements elements, opts = {}
          layout = opts[:layout] || saint.column_layout
          html = ''
          elements.each_pair do |el, el_html|
            if el.grid
              grid_elements = elements.select { |k, v| k.grid && k.grid == el.grid && elements.delete(k) }
              html << (render_grid(el.grid, grid_elements, opts) || '')
            else
              context = {layout: layout, el: el, el_html: el_html, row: opts[:row]}
              html << saint_view.render_partial('edit/element', context)
            end
          end
          html
        end

        def render_grid grid_name, elements, opts = {}
          if grid = saint.grids[grid_name]
            context = {grid: grid, elements: elements, opts: opts}
            saint_view.render_partial('edit/grid', context)
          end
        end

        def summary_columns implicit_columns, explicit_columns = nil

          columns = Array.new
          if explicit_columns.is_a?(Array)
            explicit_columns.each do |c|
              next unless column = implicit_columns[c.to_sym]
              columns << column
            end
          end
          if columns.size == 0
            implicit_columns.each_value do |column|
              next unless column.summary
              next if column.password?
              columns << column
            end
          end
          columns
        end

      end

    end

  end
end
