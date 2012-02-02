module Saint
  class ClassApi

    class OptsPool

      attr_reader :pool, :opts

      def initialize pool, table = nil, &proc
        @pool = pool || Presto::Cache::Memory.new
        @pool = @pool.new(normalize_name(table)) if table
        @opts = Hash.new
        self.instance_exec &proc
      end

      # add new opt to OptsManager.
      # 
      # @param [Symbol] name
      # @param [Hash] opts
      # @option opts [Symbol] :type (:string) one of :string, :text, :select
      # @option opts [String] :details option description
      # @option opts [Object] :default default value
      # @option opts [Hash, Array] :options options to be used by :select type
      def opt name, opts = {}
        name = normalize_name(name)
        opts['name'] = name
        opts['type'] = opts.delete(:type) || :string
        opts['details'] = opts.delete(:details)
        opts['default_value'] = opts.delete(:default)
        if options = opts.delete(:options)
          options = Hash[options.zip(options)] if options.is_a?(Array)
        end
        opts['options'] = options.is_a?(Hash) ? options : {}
        @pool[name] = opts
        @opts[name] = opts
      end

      def [] opt
        return unless item = @pool[opt]
        item['value'] || item['default_value']
      end

      def []= opt, val
        return unless item = @pool[opt]
        @pool.update opt => item.update('value' => val)
      end

      private
      def normalize_name name
        name.to_s.downcase.gsub(/\W+/, '_').gsub(/^_|_$/, '')
      end
    end

    # nodes calling this method will act as opts editor UI.
    # saint.model should be defined before this method called,
    # and have at least two columns: name and value
    #
    # opts are persisted to database, however they are not loaded every time.
    # Saint using an cache pool instead, defaulted to an memory based pool.
    # if you have multiple processes, please consider to use a persistent pool.
    #
    # @example
    #
    #    module Admin
    #      class DefaultOptions
    #        # this will use an mongodb pool
    #        saint.opts Presto::Cache::MongoDB.new(Mongo::Connection.new.db('options')) do
    #          opt :default_meta_title, default: 'TheBestSiteEver'
    #          opt :items_per_page, 10, type: :text
    #        end
    #      end
    #
    #      class EmailOptions
    #        # this will use default pool
    #        saint.opts do
    #          opt :items_per_page, default: 20
    #          opt :default_meta_title
    #          opt :admin_email, default: 'admin@TheBestSiteEver.com'
    #          opt :sales_email, default: 'sales@TheBestSiteEver.com'
    #        end
    #      end
    #    end
    #
    #    module Frontend
    #      class Controller
    #
    #        include Saint::OptsApi
    #
    #        # if multiple managers provided, it will lookup in order they was added.
    #        opts Admin::EmailOptions, Admin::DefaultOptions
    #
    #        def index
    #          opts.default_meta_title
    #          # because Admin::EmailOptions has no default value for :default_meta_title,
    #          # it will take value from DefaultOptions.
    #          # after EmailOptions GUI will update this option,
    #          # value added in GUI will be used.
    #          # also, it is using mongodb pool, so, it will get updated on both scenarios,
    #          # single and multiple processes.
    #
    #          opts.admin_email #=> admin@TheBestSiteEver.com
    #          # it is  using memory pool,
    #          # so, updates will be reflected only on process that running saint.
    #          # other processes will always use default value.
    #
    #          opts.items_per_page
    #          # will return 20, cause pools are queried in order they added.
    #        end
    #      end
    #    end
    #
    # @param pool
    #   defaulted to memory pool
    # @param table
    #   defaulted to node name
    # @param &proc
    def opts pool = nil, table = nil, &proc

      pool = OptsPool.new pool, table || @node.to_s, &proc

      # extending current node to act as an opts editor GUI.
      @node.class_exec do

        include Saint::ExtenderUtils

        define_singleton_method :opts do
          pool
        end

        define_singleton_method :opts_updater do
          orm = Saint::ORM.new saint.model, self
          pool.opts.each_pair do |opt, setup|
            if row = orm.first(name: opt)[0]
              value = row.value
            else
              value = setup['default_value']
              orm.create(name: opt, value: value)
            end
            pool[opt] = value
          end
        end

        # making sure all options are persisted.
        # well, at the little price of small overhead on backend side.
        http.before { self.class.opts_updater }

        saint.create false
        saint.delete false

        saint.grid do

          column :name, :plain do
            label 'Option'
            value do
              if row && opt = pool.opts[row.name]
                context = {
                    name: Saint::Inflector.titleize(row.name),
                    details: opt['details']
                }
                saint_view.render_view('opts/about', context)
              end
            end
          end

          column :value, :plain do
            save true
            value do
              case scope
                when :crud
                  if opt = pool.opts[row.name]
                    context = {
                        row: row,
                        options: opt['options']
                    }
                    saint_view.render_view('opts/%s' % opt['type'], context)
                  end
                when :summary
                  row.value
              end
            end
          end
        end

        saint.filter :name

        saint.after :save do |row|
          pool[row.name.to_sym] = row.value
        end

      end
    end

  end
end
