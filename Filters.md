
Text Filters
---

    saint.filter :name
    saint.filter :about
{:lang='ruby'}

*Note:* for filter to work, it should use a earlier defined column or association.

Dropdown Filters
---

    saint.filter :color, :select, options: ['red', 'green', 'blue',]
{:lang='ruby'}

or

    saint.filter :color, :select do
        options 'red', 'green', 'blue'
    end
{:lang='ruby'}

    saint.filter :type, :select, options: {0 => :Static, 1 => :Dynamic}
{:lang='ruby'}

or

    saint.filter :type, :select do
        options 0 => :Static, 1 => :Dynamic
    end
{:lang='ruby'}



Boolean Filters
---

    saint.filter :active, :boolean
{:lang='ruby'}

Associative Filters
---

Simply filter by author:

    saint.filter :author_id
        model Model::Author
    end
{:lang='ruby'}

This will create an dropdown selector containing all authors.

However, in most cases, associations contains too much items
to be displayed in a single dropdown selector.

There are two ways to solve this.

**Narrowing filters internally**

*Statical filters*

Create an dropdown selector containing only active authors.

    saint.filter :author_id
        model Model::Author do
            active: 1
        end
    end
{:lang='ruby'}

*Dynamic filters*

On example below, UI will display a dropdown containing countries
and another dropdown containing authors.

The trick is that authors will be narrowed down when a country selected and search submitted.

We can check if country is present by using `filter?`, passing needed filter as first argument.

For this to work, a proc should be passed to `model`, as per example:

    saint.filter :country_id do
        model Model::Country
    end

    saint.filter :author_id do
        model Model::Author do
            if country_id = filter?(:country_id)
                {country_id: country_id}
            end
        end
    end
{:lang='ruby'}

Make authors list to be empty until a country selected:

    saint.filter :country_id do
        model Model::Country
    end
    
    saint.filter :author_id do
        model Model::Author do
            {country_id: filter?(:country_id) || -1}
        end
    end
    # country_id is never -1,
    # so authors filter is empty until a country with valid id selected.
{:lang='ruby'}

You can combine statical filters with dynamical ones:

    saint.filter :author_id do
        model Model::Author do
            filters = {active: 1}
            if country_id = filter?(:country_id)
                filters.update country_id: country_id
            end
            filters
        end
    end
{:lang='ruby'}

This will display only active authors and filter authors by country when some country selected.

**Narrowing filters externally**

*Example:* narrow down authors by country

    saint.filter :country_id do
        model Model::Country
    end
    
    saint.filter :author_id do
        model Model::Author
        depends_on :country_id
    end
{:lang='ruby'}

This will create 2 dropdown selectors:

*   first one containing countries list and will update authors by XHR, on change.
*   second one, aimed to contain authors list, will be empty until a country selected.

And of course, narrowing filters, can also be narrowed down.
Nesting level is unlimited.

Following example above, we can narrow down the countries as well:

    saint.filter :country_name, :string
        model Model::Country
        column :name
    end
    saint.filter :country_id do
        model Model::Country
        depends_on :country_name
    end
    saint.filter :author_id do
        model Model::Author
        depends_on :country_id
    end
{:lang='ruby'}

This will create 3 fields:

*   first one is a text field, that will update countries list by XHR, on key up.
*   second one, aimed to contain countries list, will be empty until something typed in first field.
*   third one, aimed to contain authors list, will be empty until some country selected.

**Multiple narrowing filters**

It is possible to have multiple narrowing filters for a single filter.

This allow to filter authors by both country and email or any other N columns.

*Example:* narrow down authors by email and/or country

    saint.filter :author_email, :string do
      model Model::Author
      column :email
    end
    saint.filter :country_id do
        model Model::Country
    end
    saint.filter :author_id, Model::Author do
        depends_on :author_email, :country_id
    end
{:lang='ruby'}

This will create 3 fields:

*   first one is a text field, that will update authors list by XHR, on key up.
*   second one is a dropdown selector, containing countries list, that will update authors list by XHR, on change.
*   third one is a dropdown selector, aimed to contain authors list, will be empty until an email typed or a country selected.

Associative Filters - Through case
---

Say you need to filter pages by menu, and pages are associated to menus through a joining model.

To build such a filter, simply pass middle model as second argument for `model` method:

    class Page
        # defining association
        saint.has_n :menus, Model::Menu, Model::MenuPage

        # building the filter
        saint.filter :menu do
            model Model::Menu, through: Model::MenuPage
        end
    end
{:lang='ruby'}

this will create a single dropdown with a list containing all menus.

Saint expects middle model(`Model::MenuPage`) to have at least 2 columns: page_id and menu_id.

If your middle model has another considerations about this,
use `model` with :local_key and :remote_key options.

:local_key will override :page_id column and :remote_key will override :menu_id column.

    saint.filter :menu do
        model Model::Menu, through: Model::MenuPage, local_key: :p_id, remote_key: :m_id
    end
{:lang='ruby'}

Also, Saint expects your remote model(`Model::Menu`) to have :id as primary key.

If that's not the case, use :pkey option as follow:

    saint.filter :menu do
        model Model::Menu, through: Model::MenuPage, pkey: :uid
    end
{:lang='ruby'}

Associative Filters - Options
---

**:order**

By default, Saint will order remote items by remote primary key.<br/>
To have a custom order, use :order option.

*Example:* order by name, ascending:

    saint.filter :author_id do
        model, Model::Author, order :name
    end
{:lang='ruby'}

*Example:* order by name and date, both ascending:

    saint.filter :author_id do
        model, Model::Author, order [:name, :date]
    end
{:lang='ruby'}

*Example:* order by date, descending:

    saint.filter :author_id do
        model, Model::Author, order {:date => :desc}
    end
{:lang='ruby'}

*Example:* order by name(ascending) and by date(descending):

    saint.filter :author_id do
        model, Model::Author, order {:name => :asc, :date => :desc}
    end
{:lang='ruby'}

**:label**

By default, Saint will use first non ID column to build the label for dropdown options.

    saint.filter :author_id do
        model Model::Author
    end
    # HTML: <select...
    #       <option value="1">John</option>
    #       <option value="2">Alice</option>
    #       <option value="3">Bob</option>
    #       ...
{:lang='ruby'}

As seen, it ignores :id column, and uses :name.

To override this, use :label option as follow:

    saint.filter :author_id do
        model Model::Author, label: [:name, :email]
    end
{:lang='ruby'}

this will use name and email, separated by a coma.

More syntax sugar:

    saint.filter :author_id do
        model Model::Author, label: '#name, #pages.count pages'
    end
    # HTML: <select...
    #       <option value="1">John, 10 pages</option>
    #       <option value="2">Jack, 0 pages</option>
    #       ...

    saint.filter :author_id do
        model Model::Author, label: [:name, ' from #country.name']
    end
    # HTML: <select...
    #       <option value="1">John from NowhereCountry</option>
    #       <option value="2">Jack</option>
    #       ...
    # Jack has no country, so second argument ignored
{:lang='ruby'}

**:pkey**

By default, Saint will use :id for primary key of remote model.<br/>
You can use :pkey option to set a custom key:

    saint.filter :author_id do
        model Model::Author, pkey: :uid
    end
{:lang='ruby'}

**:local_key / :remote_key**

Used to define keys on join table by which local/remote models are associated.

Lets consider following example:

    class Page
        saint.model Model::Page
        saint.filter :menu do
            model Model::Menu, Model::MenuPage
        end
    end
{:lang='ruby'}

Saint will use :page_id to associate Model::Page model with Model::MenuPage model<br/>
and :menu_id to associate Model::Menu model with Model::MenuPage model.

Lets suppose that join table using :pid and :mid instead of :page_id and :menu_id.<br/>
Then we simply do like follow:

    saint.filter :menu do
        model Model::Menu, Model::MenuPage, local_key: :pid, remote_key: :mid
    end
{:lang='ruby'}


**:through**

Allow to define joining model.

    saint.filter :menu do
        model Model::Menu, through: Model::MenuPage, local_key: :p_id, remote_key: :m_id
    end
{:lang='ruby'}

**:via**

The relation name by which the remote model will communicate to local model.

By default, Saint will use pluralized model name.

*Example:* filter pages by authors name

    class Page
        saint.filter :author_name, :string do
            model Model::Author
            column :name
        end
    end
    # here Saint will use :pages
    
    class PagesModel
        saint.filter :author_name, :string do
            model AuthorModel, via: :pages
            column :name
        end
    end
    # here Saint would use :page_models by default,
    # but as this is incorrect relations name,
    # we set it by `via` method.
    
{:lang='ruby'}

Saint will send the relation name, defined by `via` option, to each found author,
building a list of pages to be displayed.

The logic is as simple as:

    pages = []
    found_authors.each do |author|
        author.pages.each { |page| pages << page }
    end
{:lang='ruby'}

As you could note, ORM relation should be defined prior to use it in Saint filters.<br/>
For DataMapper, it is as simple as:

    class Model::Author
        has n, :pages
    end
{:lang='ruby'}


More on Filters
---

Any option below can be set by pass it as argument to `saint.filter` as well as define it inside passed block.

**logic**

By default, Saint will use LIKE operator for searches.

Use :logic option or `logic` method inside filter block to override this.

It accepts 3 arguments: operator, prefix, suffix.<br/>
Both prefix and suffix will be accordingly concatenated to searched value.

Builtin operators:

*   :like
*   :eql
*   :gt
*   :gte
*   :lt
*   :lte
*   :not

Beside this, you can use any operator by passing it as string.

Return names containing "foo":

    saint.filter :name
    # SQL: SELECT FROM page WHERE name LIKE '%foo%'
{:lang='ruby'}

Return names starting with "foo":

    saint.filter :name, logic: [:like, nil, '%']
    # or
    saint.filter :name do
        logic :like, nil, '%'
    end
    # SQL: SELECT FROM page WHERE name LIKE 'foo%'
{:lang='ruby'}

Return names ending in "foo":

    saint.filter :name, logic: [:like, '%']
    # or
    saint.filter :name do
        logic :like, '%'
    end
    # SQL: SELECT FROM page WHERE name LIKE '%foo'
{:lang='ruby'}

Return items with "foo" name:

    saint.filter :name, logic: :eql
    #or
    saint.filter :name do
        logic :eql
    end
    # SQL: SELECT FROM page WHERE name = 'foo'
{:lang='ruby'}

Search by regex(postgres)

    saint.filter :name, logic: '~', '^'
    # SQL: SELECT FROM page WHERE "name" ~ '^foo'
{:lang='ruby'}

Case insensitive LIKE(postgres)

    saint.filter :name, logic: 'ILIKE'
    # SQL: SELECT FROM page WHERE "name" ILIKE '%foo%'
{:lang='ruby'}

Search by regex(mysql)

    saint.filter :name, logic: ['REGEXP', nil, '$']
    # SQL: SELECT FROM page WHERE `name` REGEXP 'foo$'
{:lang='ruby'}

**label**

By default, label is built from provided column.
To have a custom label, use `label` inside filter block:

*Example:* set :label by option

    saint.filter :color, label: 'Favourite Color'

*Example:* set :label by block

    saint.filter :name do
        label "Page Name"
    end
{:lang='ruby'}


**column**

Sometimes, various filters may need to use same columns.

To avoid column names collisions, define the real column by using :column option or `column` method inside block.

    class Page

        # search pages by name
        saint.filter :name

        # also, pages should be searched by author,
        # but there are too much authors to be displayed in a single dropdown.
        # so, the plan is to narrow down the authors by name.
        # and as :name column is already used in filters, we will use :author_name alias,
        # and set real ORM column inside filter block.

        saint.filter :author_name, :string do
            model Model::Author
            column :name
        end
        saint.filter :author_id do
            model Model::Author
            depends_on :author_name
        end
    end
{:lang='ruby'}


**options**

Used to define options for :select type.

*Example:* set :options by option

    saint.filter :status, :select, options: {1 => 'Active', 0 => 'Suspended'}
{:lang='ruby'}

*Example:* set :options by block

    saint.filter :status, :select, options: {1 => 'Active', 0 => 'Suspended'}
    # or
    saint.filter :status, :select do
        options 1 => 'Active', 0 => 'Suspended'
    end

    saint.filter :color, :select, options: ['red', 'green', 'blue']
    # or
    saint.filter :color do
        options 'red', 'green', 'blue'
    end
{:lang='ruby'}

**multiple**

Used on :select and associative filters.<br/>
If set to true, dropdown selectors will allow to select multiple options.
