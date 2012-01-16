module Saint
  class CrudExtender

    def assoc
      @node.class_exec do

        def assoc__any__remote_items relation_id, local_id, attached = 0

          unless @relation = Saint.relations[relation_id]
            return "Wrong Relation ID"
          end
          remote_node = @relation.remote_node

          page = http.params[Saint::Pager::VAR].to_i
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

              @pager = Saint::Pager.new(page, @rows_total, @relation.ipp)

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
        # updating remote_model by setting remote_key = local_id.
        #
        def assoc__has_n__update_remote_item relation_id, remote_id, local_id, action

          return unless relation = Saint.relations[relation_id]

          # getting remote item
          remote_item, @errors = relation.remote_orm.first(relation.remote_pkey => remote_id.to_i)

          if remote_item && @errors.size == 0
            # updating remote item by set its key to local_id
            val = (action == 'delete') || (local_id == ::Saint::RV_NULL_VALUE) ? nil : local_id.to_i

            # executing :before callback
            if proc = relation.before
              relation.local_node.class_exec &proc
            end

            @errors = relation.remote_orm.update(remote_item, relation.remote_key => val)[1]

          end

          json = {status: 1, error: nil}
          if @errors.size == 0

            # executing :after callback
            if proc = relation.after
              relation.local_node.class_exec &proc
            end

          else
            json[:status] = 0
            json[:error] = saint_view.render_partial("error")
          end
          json.to_json
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

          # executing :before callback
          if proc = relation.before
            relation.local_node.class_exec &proc
          end

          @errors = through_orm.send(action.to_sym, data_set)[1]

          json = {status: 1, error: nil}
          if @errors.size == 0

            # executing :after callback
            if proc = relation.after
              relation.local_node.class_exec &proc
            end

          else
            json[:status] = 0
            json[:error] = saint_view.render_partial("error")
          end
          json.to_json
        end

        private

        def assoc__any__filters method, filters = {}

          remote_items, @attached_keys_or_remote_item = 0, nil
          local_orm, remote_orm = @relation.local_orm, @relation.remote_orm
          local_pkey, remote_pkey = @relation.local_pkey, @relation.remote_pkey

          @local_item, errors = local_orm.first(local_pkey => @local_id)
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
