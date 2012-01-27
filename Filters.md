
Text Filters
---

    saint.filter :name
    saint.filter :about
{:lang='ruby'}

*Note:* for filter to work, it should use a earlier defined column or association.

Dropdown Filters
---

    saint.filter :active do
        type :select, options: {1 => 'Yes', 0 => 'No'}
    end
{:lang='ruby'}

Associative Filters
---

Simply filter by author:

    saint.belongs_to :author, Model::Author

    saint.filter :author_id, Model::Author
{:lang='ruby'}

This will create an dropdown selector containing all authors.

However, in most cases, associations contains too much items
to be displayed in a single dropdown selector.

There are two ways to solve this.

**Narrowing filters internally**

*Statical filters*

Create an dropdown selector containing only active authors.

    saint.filter :author_id, Model::Author do
        filter active: 1
    end
{:lang='ruby'}

*Dynamic filters*

On example below, UI will display a dropdown containing countries
and another dropdown containing authors.

The trick is that authors will be narrowed down when a country selected and search submitted.

This is dome by given block, that extracts the selected country ID using #filter?,
and return a hash containing extracted ID, narrowing authors to only ones in selected country.

Proc should return a hash.

    saint.filter :country_id, Model::Country

    saint.filter :author_id, Model::Author do
        filter do
            if country_id = filter?(:country_id)
                {country_id: country_id}
            end
        end
    end
{:lang='ruby'}

Make authors list to be empty until a country selected:

    saint.filter :country_id, Model::Country
    
    saint.filter :author_id, Model::Author do
      filter do
        {country_id: filter?(:country_id) || -1}
      end
    end
    # country_id will never be -1,
    # so authors filter is empty until a country with valid id selected.
{:lang='ruby'}

You can combine statical filters with dynamical ones:

    saint.filter :some_column, Some::Model do
        filter active: 1 do |params|
            # some logic
        end
    end
{:lang='ruby'}

On keys collisions, dynamic filters will override statical ones.

**Narrowing filters externally**

*Example:* narrow down authors by country

    saint.filter :country_id, Model::Country
    
    saint.filter :author_id, Model::Author do
        depends_on :country_id
    end
{:lang='ruby'}

This will create 2 dropdown selectors:

*   first one containing countries list and will update authors by XHR, on change.
*   second one, aimed to contain authors list, will be empty until a country selected.

And of course, narrowing filters, can also be narrowed down.
Nesting level is unlimited.

Following example above, we can narrow down the countries as well:

    saint.filter :country_name, Model::Country do
        type :string
        column :name
    end
    saint.filter :country_id, Model::Country do
        depends_on :country_name
    end
    saint.filter :author_id, Model::Author do
        depends_on :country_id
    end
{:lang='ruby'}

This will create 3 fields:

*   first one is a text field, that will update countries list by XHR, on key up.
*   second one, aimed to contain countries list, will be empty until something typed in first field.
*   third one, aimed to contain authors list, will be empty until some country selected.

**Multiple narrowing filters**

It is possible to have multiple narrowing filters for same filter.

This allow to filter authors by both country and email or any other N columns.

*Example:* narrow down authors by email and/or country

    saint.filter :author_email, Model::Author do
      type :string
      column :email
    end
    saint.filter :country_id, Model::Country
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

    class Page
        # defining association
        saint.has_n :menus, Model::Menu, Model::MenuPage

        # building the filter
        saint.filter :menu, Model::Menu, Model::MenuPage
    end
{:lang='ruby'}

this will create a single dropdown containing menu list.

Saint expects middle model(Model::MenuPage) to have at least 2 columns: page_id and menu_id.

If your middle model has another considerations about this,
use `local_key` and `remote_key` inside filter block.

\#local_key will override :page_id column and #remote_key will override :menu_id column.

    saint.filter :menu, Model::Menu, Model::MenuPage do
        local_key :p_id
        remote_key :m_id
    end
{:lang='ruby'}

Also, Saint expects your remote model(Model::Menu) to have :id as primary key.

If that's not the case, use #remote_pkey:

    saint.filter :menu, Model::Menu, Model::MenuPage do
        remote_pkey :uid
    end
{:lang='ruby'}

More on Associative Filters
---

**order**

Saint will display association items in the order they was extracted.
To have a custom order, use `order` inside filter block:

    saint.filter :author_id, Model::Author do
        order :name
    end
{:lang='ruby'}

This will order authors by name.

**column**

Sometimes, associative filters have to use same columns as host.

To avoid columns collisions, use #column to define the real ORM column.

    class Page

        # search pages by name
        saint.filter :name

        # also, pages should be searched by author,
        # but there are too much authors to be displayed in a single dropdown.
        # so, the plan is to narrow down the authors by name.
        # and as :name column is already used in filters, we will use :author_name alias,
        # and set real ORM column inside filter block.

        saint.filter :author_name, Model::Author do
            column :name
            type :string
        end
        saint.filter :author_id, Model::Author do
            depends_on :author_name
        end
    end
{:lang='ruby'}

**option_label**

By default, Saint will use first 2 non ID columns to build the label for dropdown options.

    saint.filter :author_id, Model::Author
    # HTML: <select...
    #       <option value="1">John, john@doe.com</option>
    #       <option value="2">Alice, alice@dot.com</option>
    #       <option value="3">Bob, bob@dot.com</option>
    #       ...
{:lang='ruby'}

As seen, it ignores :id column, and uses :name.

To override this, use `option_label` inside filter block:

    saint.filter :author_id, Model::Author do
        option_label :name, :email
    end
{:lang='ruby'}

this will use only name and email, separated by a coma.

More syntax sugar:

    saint.filter :author_id, Model::Author do
        option_label :name, ' from #country.name'
    end
    # HTML: <select...
    #       <option value="1">John from NowhereCountry</option>
    #       <option value="2">Jack</option>
    #       ...
    # Jack has no country, so second argument ignored
    
    saint.filter :author_id, Model::Author do
        option_label :name, '#pages.count pages'
    end
    # HTML: <select...
    #       <option value="1">John, 10 pages</option>
    #       ...
{:lang='ruby'}

More on Filters
---

**label**

By default, label is built from provided column.
To have a custom label, use `label` inside filter block:

    saint.filter :name do
        label "Page Name"
    end
{:lang='ruby'}

**type**

Available types:

*   :string
*   :select

Type is defaulted to :string for non-associative filters and to :select from associative ones.

To override this, use `type` inside filter block.

`type` accepts :options option, used as options on :select type.

Options can also be provided via block, just make sure given block returns a string for :string filters
and an hash or array for :select type.

*Example:* set options by option

    saint.filter :status do
        type :select, options: {1 => 'Active', 0 => 'Suspended'}
    end
{:lang='ruby'}

*Example:* set options by block

    saint.filter :status do
        type :select do
            {1 => 'Active', 0 => 'Suspended'}
        end
    end
{:lang='ruby'}

**logic**

By default, db query will be built using LIKE logic.

Use `logic` inside filter block to override this.

It accepts 3 arguments: logic, prefix, suffix.<br/>
Both prefix and suffix will be accordingly concatenated to searched value.

Available logics:

*   :like
*   :eql
*   :gt
*   :gte
*   :lt
*   :lte
*   :not

Return names containing "foo":

    saint.filter :name
    # SQL: SELECT FROM page WHERE name LIKE '%foo%'
{:lang='ruby'}

Return names starting with "foo":

    saint.filter :name do
        logic :like, nil, '%'
    end
    # SQL: SELECT FROM page WHERE name LIKE 'foo%'
{:lang='ruby'}

Return names ending in "foo":

    saint.filter :name do
        logic :like, '%'
    end
    # SQL: SELECT FROM page WHERE name LIKE '%foo'
{:lang='ruby'}

Return "foo" names:

    saint.filter :name do
        logic :eql
    end
    # SQL: SELECT FROM page WHERE name = 'foo'
{:lang='ruby'}
