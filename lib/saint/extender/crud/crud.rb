module Saint
  class CrudExtender

    def initialize node
      @node = node
      @node.send :include, Saint::Utils
      helpers; assoc; filter; crud
      Saint::ORMUtils.finalize
    end

    def crud
      @node.class_exec do

        def index

          orm_filters, http_filters = saint.filter_instances(:orm, :http)
          page = http.params[Saint::Pager::VAR].to_i
          @rows_total, @errors = saint.orm.count orm_filters
          if @errors.size == 0

            @pager = Saint::Pager.new(page, @rows_total, saint.ipp)
            @pager.paginate(query: http_filters.join('&'))

            limits = @rows_total > saint.ipp ? saint.orm.limit(
                saint.ipp,
                @pager.page_number * saint.ipp
            ) : {}

            order = saint.orm.order(saint.ordered.orm || saint.order)

            @rows, @errors = saint.orm.filter(orm_filters.merge(limits).merge(order))
            @columns = summary_columns(saint.column_instances) if @errors.size == 0
            @__meta_title__ = saint.label
          end
          partial = @errors.size > 0 ? 'error' : 'list/list'
          saint_view.render_layout saint_view.render_partial(partial)
        end

        def edit row_id = 0

          @row_id = row_id.to_i
          @row, @errors = @row_id > 0 ?
              saint.orm.first(saint.pkey => @row_id) :
              saint.orm.new
          unless @row
            error = 'Item not found'
            error = saint_view.render_partial('error') if @errors.size > 0
            http.halt error, status: 500
          end

          @__meta_title__ = saint.h @row

          orm_filters, http_filters = saint.filter_instances(:orm, :http)
          @pager = Saint::Pager.new(http.params[Saint::Pager::VAR].to_i)
          @pager.paginate(query: http_filters.join('&'), skip_render: true)

          @rows = Hash.new
          if (rows_total = saint.orm.count(orm_filters)[0].to_i) > 0
            l, o = saint.ipp + 2, (@pager.page_number * saint.ipp) - 1
            limits = rows_total > saint.ipp ? saint.orm.limit(l, o < 0 ? 0 : o) : {}
            rows, errors = saint.orm.filter(orm_filters.merge(saint.orm.order(saint.order).merge(limits)))
            if rows.is_a?(Array) && rows.size > 0 && errors.size == 0

              index, n = 0, rows_total - o
              @rows = rows.inject({}) do |map, r|
                id = r.send(saint.pkey)
                index = map.size if @row_id == id
                page = @pager.page_label
                page -= 1 if map.size == 0
                page += 1 if map.size == rows.size - 1 unless (n -= 1) == 0
                map.update map.size => [r, page, n]
              end

              @prev = @rows[index-1]
              @next = @rows[index+1]

            end
          end

          @elements = crud_columns(saint.column_instances, @row)
          saint_view.render_layout saint_view.render_partial('edit/edit')
        end

        def save row_id = 0

          is_new, assoc_updated = false, nil
          if saint.update
            ds, belongs_to = Hash.new, Hash.new
            saint.column_instances.select { |n, c| c.save? }.each_value do |column|

              value = http.params[column.name.to_s]

              # nil columns are not saved/updated
              # to set column's value to nil, use SaintConst::NULL_VALUE as column value
              unless value
                # exception making only checkbox columns, which can be nil
                next unless column.checkbox?
              end

              # joining values for checkbox and select-multiple columns
              value = value.join(column.join_with) if value.is_a?(Array)

              value = nil if value == SaintConst::NULL_VALUE

              if value && rb_wrapper = saint.rbw
                value = rb_wrapper.unwrap(value)
              end
              ds[column.name] = value
            end

            (saint.belongs_to||{}).each_value do |a|
              local_key = a.local_key.to_s
              next unless value = http.params[local_key]
              assoc_updated = a if http.params.size == 1 && http.params.keys.first == local_key
              value = value == SaintConst::NULL_VALUE ? nil : value.to_i
              belongs_to[a] = value
            end

            @errors = []
            saint.column_instances.select { |n, c| c.required? && c.save? }.each_key do |column|
              @errors << '%s is required' % column unless ds[column]
            end

            if @errors.size == 0
              if (row_id = row_id.to_i) > 0
                @row, @errors = saint.orm.first(saint.pkey => row_id)
                ds.each_pair { |c, v| @row[c] = v }

                # avoiding infinite loops
                is_loop = false
                if @row && @errors.size == 0
                  # just for convenience
                  current_item_id = row_id
                  belongs_to.select { |a, v| a.is_tree? }.each_pair do |assoc, opted_parent_id|

                    # fail if opted parent and current item are the same
                    is_loop = true if current_item_id == opted_parent_id

                    # fail if opted parent is a direct or nested child of current item
                    get_nested_children = lambda do |parent_id|
                      (assoc.local_orm.filter(assoc.local_key => parent_id)[0]||[]).each do |child|
                        child_id = child.send(assoc.local_pkey)
                        is_loop = true if child_id == opted_parent_id
                        get_nested_children.call(child_id) unless is_loop
                      end
                    end
                    get_nested_children.call(current_item_id) unless is_loop

                  end
                end
                if is_loop
                  @errors = 'Infinite loop detected'
                else
                  belongs_to.each_pair { |a, val| @row[a.local_key] = val }
                end
              else
                is_new = true
                belongs_to.each_pair { |a, val| ds[a.local_key] = val }
                @row, @errors = saint.orm.new(ds)
              end

              if @row && @errors.size == 0
                @row, @errors = saint.orm.save(@row)
              end
            end
          else
            @errors = ['Update capability disabled by admin']
          end

          if @errors.size > 0
            status = 0
            message = saint_view.render_partial('error')
          else
            status = @row[saint.pkey]
            label = assoc_updated ? '"%s :%s" association' % [assoc_updated.type, assoc_updated.name] : saint.label(singular: true)
            message = (is_new ? 'New %s successfully created' : '%s successfully updated') % label
          end
          {status: status, message: message}.to_json
        end

        def head row_id
          if row = saint.orm.first(saint.pkey => row_id.to_i)[0]
            saint.h row
          end
        end

        def delete row_id = nil

          status = 0
          if saint.delete

            rows = [row_id.to_i].concat(http.post_params['rows']||[]).
                map { |id| id.to_i }.
                select { |id| id > 0 }.uniq

            message = 'No items selected'
            if rows.size > 0

              @errors = saint.orm.delete(saint.pkey => rows)[1]

              if @errors.size > 0
                message = saint_view.render_partial('error')
              else
                status = 1
                message = '%s %s successfully deleted!' % [rows.size, saint.label(singular: rows.size == 1)]
              end

            end
          else
            message = 'Delete capability disabled by admin'
          end
          {status: status, message: message}.to_json
        end

      end
    end
  end
end
