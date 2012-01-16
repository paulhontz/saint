
Opts Manager is a simple UI for editing predefined options.

Saint nodes calling #saint.opts will act as opts editor UI.

Model should be defined(via saint.model(Model)) before #saint.opts called.

Given model should have at least two columns: name and value.

To define a opt, use #opt inside block:

    saint.opts do
        opt :favourite_author
    end

**Options accepted by #opt:**

*   :type - one of :string, :text, :select. defaulted to :string
*   :default - default value. to be used until you edit it.
*   :options - options to be used by :select type.

*Examples:*

    saint.opts do

        opt :some_opt
        # UI will draw an text input

        opt :some_opt, type: :text
        # UI will draw an textarea

        opt :some_opt, type: :text, default: 'some value'
        # UI: <textarea...>some value</textarea>

        opt :status, type: :select, options: {1=>'Active', 0=>'Suspended'}
        # UI: <select...>
        #     <option value="1">Active</option>
        #     <option value="0">Suspended</option>
        
        opt :color, type: :select, options: ['red', 'green', 'blue'], default: 'green'
        # UI: <select...>
        #     <option value="red">red</option>
        #     <option value="green" selected>green</option>
        #     <option value="blue">blue</option>
    end

Opts are persisted to database, however they are not loaded every time.

Saint using an cache pool instead, defaulted to an memory based pool.

If you have multiple processes, please consider to use a persistent pool,
by passing it as #opts first argument.

*Example:* creating UI

    module Admin
    
        class DefaultOptions
            # this will use an mongodb pool
            pool = Presto::Cache::MongoDB.new(Mongo::Connection.new.db('options'))
            saint.opts pool do
                opt :default_meta_title, default: 'TheBestSiteEver'
                opt :items_per_page, 10, type: :text
            end
        end

        class EmailOptions
            # this will use default pool
            saint.opts do
                opt :items_per_page, default: 20
                opt :default_meta_title
                opt :admin_email, default: 'admin@TheBestSiteEver.com'
                opt :sales_email, default: 'sales@TheBestSiteEver.com'
            end
        end
    end

After Opts Managers defned, any class may include Saint::OptsApi and read options via #opts method.

The scenarion is a s simple as:

*   include Saint::OptsApi
*   let saint know what managers to read opts from: opts Manager1, Manager2
*   use #opts to read options: opts.some_options, opts.some_another_option

*Example:*

    module Frontend
        class Controller

            include Saint::OptsApi

            # multiple Managers supported
            # using managers defined in previous example
            opts Admin::EmailOptions, Admin::DefaultOptions

            def index
                opts.default_meta_title
                opts.admin_email
                opts.items_per_page
            end
        end
    end

