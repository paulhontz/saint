module Saint
  class CrudExtender

    def initialize node
      @node = node
      @node.send :include, Saint::ExtenderUtils
      helpers; assoc; filter; crud
      Saint::ORMUtils.finalize
    end

    def crud
      @node.class_exec do

        def index

          orm_filters, http_filters = saint.filters(:orm, :http)
          page = http.params[Saint::Pager::VAR].to_i
          @rows_total, @errors = saint.orm.count orm_filters
          if @errors.size == 0

            @pager = Saint::Pager.new(page, @rows_total, saint.ipp)
            @pager.paginate(query: http_filters.join('&'))

            limits = @rows_total > saint.ipp ? saint.orm.limit(
                saint.ipp,
                @pager.page_number * saint.ipp
            ) : {}
            order = saint.orm.order(saint.order)

            @rows, @errors = saint.orm.filter(orm_filters.merge(limits).merge(order))
            @columns = summary_columns(saint.columns) if @errors.size == 0
            http.flash[Saint::RV_META_TITLE] = saint.h
          end
          partial = @errors.size > 0 ? 'error' : 'list/list'
          view.render_layout saint_view.render_partial(partial)
        end

        def edit row_id = 0

          @row_id = row_id.to_i
          @row, @errors = @row_id > 0 ?
              saint.orm.first(saint.pkey => @row_id) :
              saint.orm.new
          unless @row
            error = "Item not found"
            error = saint_view.render_partial("error") if @errors.size > 0
            http.halt error, status: 500
          end

          http.flash[Saint::RV_META_TITLE] = '%s | %s' % [saint.h, saint.h(@row)]

          orm_filters, http_filters = saint.filters(:orm, :http)
          @pager = Saint::Pager.new(http.params[Saint::Pager::VAR].to_i)
          @pager.paginate(query: http_filters.join('&'), skip_render: true)

          if  @row_id > 0

            # decrementing offset just in case the current item is first on page
            offset = (@pager.page_number * saint.ipp) - 2
            # incrementing limit just in case the current item is last on page
            limit = saint.ipp + 2

            offset = 0 if offset < 0
            limits = saint.orm.limit(limit, offset)
            order = saint.orm.order(saint.order)
            rows, errors = saint.orm.filter(orm_filters.merge(limits).merge(order))
            if errors.size == 0 && (rows = rows.to_a rescue nil)
              if i = rows.index { |o| o.send(saint.pkey) == @row_id }
                @prev_item = i == 0 && offset == 0 ? nil : rows[i-1]
                @next_item = rows[i+1]
              end
            end
          end

          @elements, @password_elements = render_columns(saint.columns, :crud, @row)
          view.render_layout saint_view.render_partial('edit/edit')
        end

        def xhr_edit row_id = 0

          @row, @errors = (row_id = row_id.to_i) > 0 ?
              saint.orm.first(saint.pkey => row_id) :
              saint.orm.new

          if @errors.size > 0
            return saint_view.render_partial('error')
          end

          @elements = Hash.new
          saint.columns.select { |n, c| c.crud }.each_value do |column|
            @row_val = column.crud_value @row
            @element = column
            @elements[column] = column.type ?
                saint_view.render_partial('edit/elements/%s' % @element.type) :
                @row_val
          end
          saint_view.render_partial('edit/xhr')
        end

        def save row_id = 0

          if saint.update
            ds = Hash.new
            saint.columns.select { |n, c| c.save }.each_value do |column|
              value = http.params[column.name.to_s]
              # nil columns are not saved/updated.
              # to set an column's value to nil, use {Saint::RV_NULL_VALUE} as column value
              next unless value
              value = nil if value == ::Saint::RV_NULL_VALUE
              if value && rb_wrapper = saint.rbw
                value = rb_wrapper.unwrap(value)
              end
              ds[column.name] = value
            end
            if belongs_to = saint.belongs_to
              belongs_to.each_value do |a|
                next unless value = http.params[a.local_key.to_s]
                value = nil if value == ::Saint::RV_NULL_VALUE
                ds[a.local_key] = value
              end
            end

            if (row_id = row_id.to_i) > 0
              @row, @errors = saint.orm.first(saint.pkey => row_id)
            else
              @row, @errors = saint.orm.new(ds)
            end

            if @errors.size == 0
              ds.each_pair { |c, v| @row[c] = v } if row_id > 0
              @row, @errors = saint.orm.save @row
            end
          else
            @errors = ['Update capability disabled by admin']
          end

          if @errors.size > 0
            json = {error: saint_view.render_partial("error"), status: 0}
          else
            alert = "Item successfully saved at " + current_time
            http.flash[:alert] = alert
            json = {alert: alert, status: @row[saint.pkey]}
          end
          json.to_json
        end

        def save_password row_id, updated_column

          if saint.update
            return unless column = saint.columns[updated_column.to_sym]

            row_id = row_id.to_i
            row, @errors = saint.orm.first(saint.pkey => row_id)

            if row && @errors.size == 0

              value, confirmation = http.post_params.values_at(updated_column, updated_column + '_confirm')

              if value == confirmation
                @errors = saint.orm.update(row, column.name => value)[1]
              else
                @errors = ["Passwords mismatch"]
              end
            end
            alert = column.label + " updated successfully!"
            alert = saint_view.render_partial("error") if @errors.size > 0
          else
            alert = 'Update capability disabled by admin'
          end

          http.flash[:alert] = alert
          http.redirect http.post_params['redirect-to'] || http.route(:edit, row_id)
        end

        def delete row_id = nil

          if saint.delete

            rows = [row_id ? row_id.to_i : nil]
            (http.post_params['rows']||Array.new).each do |id|
              rows << id.to_i if id.to_i > 0
            end
            rows = rows.compact.uniq
            rows.delete(0)

            alert = "No items selected"
            if rows.size > 0

              @errors = saint.orm.delete(saint.pkey => rows)[1]

              alert = "Item(s) deleted!"
              alert = saint_view.render_partial("error") if @errors.size > 0

            end
          else
            alert = 'Delete capability disabled by admin'
          end
          http.flash[:alert] = alert
          http.redirect(http.params['redirect_to'] || http.route)
        end

      end
    end
  end
end
