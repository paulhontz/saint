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

By default, Saint will create a column for each property found on given model
(excluding ones of unsupported types as well as primary and foreign keys).

Automatically created columns can be later fine tuned, by using `saint.column`
or removed from list, by using `saint.ignore`.

Saint supports columns of various types. Below are some of them.

###Dropdown

    saint.column :status, :select, options: {1 => :Active, 0 => :Suspended}

<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/select.png" class="screenshot" />
</div>


###Boolean

Renders an radio selector with 2 options: 1 => 'Yes' and 0 => 'No'

    saint.column :active, :boolean

<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/boolean.png" class="screenshot" />
</div>

### Rich Text Editor

    saint.column :content, :rte

<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/page-rte.png" class="screenshot" />
</div>


[More on Columns](http://saintrb.org/Columns.md)


Associations
---

The types of associations currently supported by Saint are:

*   belongs to
*   has N
*   has N through

*Example:* Game belongs to Edition

    class Game
        saint.belongs_to :edition, Model::Edition
    end

*Example:*  Game has N Goals

    class Game
        saint.has_n :goals, Model::Goal
    end


*Example:* Game has N Scorers(Players), through PlayersScorers model

    class Game
        saint.has_n :scorers, Model::Player, Model::PlayersScorers
    end


[More on Associations](http://saintrb.org/Associations.md)

Filters
---

**Text Filters**

    saint.filter :name
    saint.filter :about


*Note:* for filter to work, it should use a earlier defined column or association.

**Dropdown Filters**

    saint.filter :active, :select, options: {1 => 'Yes', 0 => 'No'}


**Associative Filters**

Filter Page by Author:

    saint.filter :author_id do
        model Model::Author
    end


[More on Filters](http://saintrb.org/Filters.md)

File Manager
---

Saint comes with a built-in file manager.

Simply let Saint know the full path to folder and it will turn a class into a fully fledged file manager

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
