module Saint
  class CrudExtender

    def assoc
      @node.class_exec do

        def assoc__any__remote_items relation_id, local_id = 0, attached = 0

          unless @relation = Saint.relations[relation_id]
            return "Wrong Relation ID"
          end
          remote_node = @relation.remote_node

          @attached = attached.to_i
          @local_id = local_id.to_i
          @rows, @rows_total = Array.new, 0

          # no filters by default
          orm_filters, http_filters = {}, []

          if remote_node
            # however, if remote node provided,
            # filters defined by remote node will be applied here.
            orm_filters, http_filters = remote_node.saint.filters(http.params, :orm, :http)
          end

          @remote_items = Array.new
          @rows_total, @errors = assoc__any__filters(:count, orm_filters)
          if @errors.size == 0

            if remote_node && @rows_total == 0
              # if no items found by filters defined by remote node,
              # clearing filters and trying new search.
              orm_filters, http_filters = {}, []
              @rows_total = assoc__any__filters(:count, orm_filters)[0]
            end

            if @rows_total > 0

              @pager = Saint::Pager.new(http.params[Saint::Pager::VAR].to_i, @rows_total, @relation.ipp)

              limits = @rows_total > @relation.ipp ? saint.orm.limit(
                  @relation.ipp,
                  @pager.page_number * @relation.ipp
              ) : {}
              order = saint.orm.order(@relation.order)

              filters = orm_filters.merge(limits).merge(order)
              @remote_items, @errors = assoc__any__filters(:filter, filters)

              if @errors.size == 0

                @pager.paginate(
                    route: http.route(__method__, @relation.id, @local_id, @attached),
                    query: http_filters.join('&'),
                    template: :assoc,
                    container_id: @relation.id + @attached.to_s
                )
                @remote_columns = summary_columns(@relation.columns)
              end
            end
          end
          saint_view.render_partial @errors.size > 0 ? 'error' : 'list/assoc/%s' % @relation.type
        end

        #
        # updating remote_model by setting remote_key equal to local_id.
        #
        def assoc__has_n__update_remote_item relation_id, remote_id, local_id, action

          return unless relation = Saint.relations[relation_id]

          remote_id = remote_id.to_i
          local_id = (action == 'delete') || (local_id == SaintConst::NULL_VALUE) ? nil : local_id.to_i

          # getting remote item
          remote_item, @errors = relation.remote_orm.first(relation.remote_pkey => remote_id)

          if remote_item && @errors.size == 0
            # avoiding infinite loops
            if relation.is_tree? && local_id && local_id > 0

              is_loop = false

              # just for convenience
              current_item_id = remote_id
              opted_parent_id = local_id

              # fail if opted parent and current item are the same
              is_loop = true if current_item_id == opted_parent_id

              # fail if opted parent is a direct or nested child of current item
              get_nested_children = lambda do |parent_id|
                (relation.local_orm.filter(relation.local_key => parent_id)[0]||[]).each do |child|
                  child_id = child.send(relation.local_pkey)
                  is_loop = true if child_id == opted_parent_id
                  get_nested_children.call(child_id) unless is_loop
                end
              end
              get_nested_children.call(current_item_id) unless is_loop

              is_loop && @errors = 'Infinite loop detected'
            end
            if @errors.size == 0
              # executing :before callback, if any
              relation.before && relation.local_node.class_exec(&relation.before)
              # updating remote item by set its key to local_id
              @errors = relation.remote_orm.update(remote_item, relation.remote_key => local_id)[1]
            end
          end

          return {status: 0, message: saint_view.render_partial('error')}.to_json if @errors.size > 0
          # executing :after callback, if any
          relation.after && relation.local_node.class_exec(&relation.after)
          {status: local_id, message: '"%s :%s" association successfully updated' % [relation.type, relation.name]}.to_json
        end

        #
        # simply altering middle model by creating/deleting rows
        # containing local and remote keys.
        #
        def assoc__has_n__update_through_model relation_id, remote_id, local_id, action

          return unless relation = Saint.relations[relation_id]
          return unless through_orm = relation.through_orm

          data_set = {
              relation.local_key => local_id.to_i,
              relation.remote_key => remote_id.to_i,
          }

          # executing :before callback, if any
          relation.before && relation.local_node.class_exec(&relation.before)

          @errors = through_orm.send(action.to_sym, data_set)[1]

          return {status: 0, message: saint_view.render_partial('error')}.to_json if @errors.size > 0
          # executing :after callback, if any
          relation.after && relation.local_node.class_exec(&relation.after)
          {status: local_id, message: '"%s :%s" association successfully updated' % [relation.type, relation.name]}.to_json
        end

        private

        def assoc__any__filters method, filters = {}

          remote_items, @attached_keys_or_remote_item = 0, nil
          local_orm, remote_orm = @relation.local_orm, @relation.remote_orm
          local_pkey, remote_pkey = @relation.local_pkey, @relation.remote_pkey

          errors = []
          @local_item, errors = local_orm.first(local_pkey => @local_id) if @local_id > 0
          remote_node = @relation.remote_node

          # adding filters defined inside relation block.
          if relation_filters = @relation.filters(@local_item)
            # but adding only if there are no http filters in act.
            filters.update(relation_filters) unless remote_node && remote_node.saint.filters?(http.params)
          end

          if errors.size == 0

            # action params contains :attached bit,
            # when 0 action will return all children,
            # when 1 action will return only attached children.
            if @attached == 0

              # step 1: extracting the full list of remote items
              remote_items, errors = remote_orm.send(method, filters)

              if errors.size == 0

                # step 2: extracting attached children
                # cause even when :attached is 0,
                # we need the list of attached children,
                # to mark them as attached when displayed.
                if @local_item && method == :filter

                  case @relation.type

                    when :has_n

                      # for :has_n association, we extract remote items
                      # by sending association name to local model.
                      # ie, if local model is :folder and remote is :file,
                      # we extracting files by this: folder.send(files)
                      @attached_keys_or_remote_item = Array.new
                      @local_item.send(@relation.name).each do |remote_item|
                        @attached_keys_or_remote_item << remote_item[remote_pkey]
                      end

                    when :belongs_to

                      # for :belongs_to association, we need to compare
                      # local_key against remote pkey.
                      # ie, if :file belongs to :folder,
                      # by default, :file's local_key is :folder_id,
                      # so, we have to compare :file#folder_id against :folder#id
                      # which effectively compares
                      # local_model#local_key against remote_model#remote pkey
                      @attached_keys_or_remote_item, errors = remote_orm.first(
                          remote_pkey => @local_item[@relation.local_key]
                      )
                  end
                end
              end

            else

              # when :attached is 1, extracting only attached remote items,
              # by sending relation#name to local item.
              # not needed on :belongs_to associations
              if @local_item && @relation.has_n?

                attached_keys = Array.new
                @local_item.send(@relation.name).each do |remote_item|
                  attached_keys << remote_item[remote_pkey]
                end
                filters.update(remote_pkey => attached_keys)
                remote_items, errors = remote_orm.send(method, filters)
              end
            end
          end
          [remote_items, errors]
        end

      end
    end
  end
end
