Quick Start
---

Saint allow developers to easily manage existing ORM models(currently only DataMapper supported).

It is aimed to automatize the backend building process, by creating **Summary** and **CRUD** pages.

**Install:**

    $ [sudo] gem install saint

**Define Model:**

    class PageModel
        include DataMapper::Resource
        property :id, Serial
        property :name, String
    end


**Setup Controller:**

    class Page
        include Saint::Api
        http.map :pages
        saint.model PageModel
    end


**Deploy:**

    app = Presto::App.new
    app.mount Page
    app.run


[Tutorial](http://demo.saintrb.org/)

Columns
---

By default, Saint will manage all columns found on given model
(except ones of unsupported types as well as primary and foreign keys).

You can instruct Saint to manage only some columns or ignore some of them.

@example: manage only :name and :email

    class Author
        include Saint::Api
        saint.model AuthorModel do
            columns :name, :email
        end
    end

@example: manage all columns but :created_at

    class Page
        include Saint::Api
        saint.model PageModel do
            columns_ignored :created_at
        end
    end

Automatically created columns can be later fine-tuned, by using `saint.column`.

@example convert :content into Rich Text Editor

    class Page
        include Saint::Api
        saint.model PageModel
        saint.column :content, :rte
    end

[More on Columns](http://saintrb.org/Columns.md)


Associations
---

Saint will manage all associations found on given model.

You can decide what associations to be managed and which to be ignored.

@example: manage only :author relation

    # DataMapper model
    class PageModel
        # basic setup
        belongs_to :author
        has n, :menus
        has n, :visits
    end

    # Saint setup
    class Page
        include Saint::Api
        saint.model PageModel do
            relations :author
        end
    end

@example: manage all relations but :visits

    class Page
        include Saint::Api
        saint.model PageModel do
            relations_ignored :visits
        end
    end

Automatically defined associations can be fine-tuned later.

@example: manage :visits relations in readonly mode

    class Page
        include Saint::Api
        saint.model PageModel
        saint.has_n :visits, VisitsModel, readonly: true
    end

[More on Associations](http://saintrb.org/Associations.md)

Filters
---

Saint will also build filters for each property found on given model.

As per columns and associations, you can decide what filters to build and which ones to ignore.

@example: build filters only for :name and :email

    class Author
        include Saint::Api
        saint.model AuthorModel do
            filters :name, :email
        end
    end

@example: build filters for all columns but :visits

    class Page
        include Saint::Api
        saint.model PageModel do
            filters_ignored :visits
        end
    end

And of course, any automatically built filter can be fine-tuned.

@example: convert :color filter into a dropdown with multiple options

    class Menu
        include Saint::Api
        saint.model MenuModel
        filter :color, :select, options: [:red, :green, :blue], multiple: true
    end


[More on Filters](http://saintrb.org/Filters.md)

File Manager
---

Saint comes with a built-in file manager.

Simply let Saint know the full path to folder and it will turn a class into a fully-fledged file manager

    class FileManager

        include Saint::Api
        http.map 'file-manager'

        saint.fm do
            root '/full/path/to/folder'
        end

    end


[More on File Manager](http://saintrb.org/FileManager.md)


Opts Manager
---

Saint also has an built-in Opts Manager, which is a simple UI for editing predefined options.

Any class may include `Saint::OptsApi` and get an extra Api, via `opts` method.

Options defined inside Opts Manager can be accessed by `opts` Api.

    # creating Opts Manager UI
    class Admin
        include Saint::Api

        saint.opts do
            opt :items_per_page, default: 10
        end
    end

    # making use of Opts Api in some frontend class
    class Pages
        include Saint::OptsApi

        # lets saint know what Opts Manager to use
        opts Admin

        # now you can use opts.items_per_page anywhere in your class and its instances.

        opts.items_per_page # will return 10, until you edit it via UI

        def index
            opts.items_per_page # available in class instances as well
        end
    end


[More on Opts Manager](http://saintrb.org/OptsManager.md)
