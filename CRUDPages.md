###Header

Defaulted to pluralized model name

To have a custom header for both Summary and CRUD pages, use *saint.header*:

    class Pages
        include Saint::Api

        saint.model Model::Page
        # header is(yet) "Pages"

        saint.header 'CMS Pages'
        # header now is "CMS Pages"
    end

To have an even more useful header, use a proc.

The proc will receive back the current row.

    saint.header 'CMS Pages' do |row|
        row.name
    end
    # now the header on CRUD pages will be
    # CMS Pages : [page name]

To achieve same result without a block, pass methods to be called inside block as arguments:

    saint.header 'CMS Pages', :name
    # now the header on CRUD pages will be
    # CMS Pages : [page name]
    
    saint.header 'Pages', '#name by #author.name', '#views views'
    # now the header on CRUD pages will be
    # Pages : [page name] by [author name], [views] views


###Labels

By default, Saint will use capitalized name for column label:

    saint.column :name
    # HTML: <fieldset><legend>Name</legend>...

To have an custom label, use :label option:

    saint.column :name, label: "Author's Name"
    # HTML: <fieldset><legend>Author's Name</legend>...


###Grids

By default, columns are separated by a new line.

Use *saint.grid* to have N columns placed on same line:

    saint.grid do
      column :meta_title
      column :meta_description
      column :meta_keywords
    end
    # [meta_title]  [meta_description]  [meta_keywords]

This will place all columns on same line.

To have a break line after each N columns, use :columns option:

    saint.grid columns: 2 do
      column :meta_description
      column :meta_keywords
      column :meta_title
    end
    # [meta_description] [meta_keywords]
    # [meta_title]

Comprise grid in some layout:

    saint.grid header: '<div class="meta-layout">', footer: '</div>' do
        column :meta_title
        column :meta_description
        column :meta_keywords
    end

Saint will render all columns by equal width (100 / columns)%

To have a custom width/height for some column, use :grid_width and :grid_height options:

    saint.grid do
      column :meta_title, grid_width: '50%'
      column :meta_description, grid_height: 200
      column :meta_keywords, grid_height: 200
    end

Numerical widht/height are used as pixels.

###Tabs

If you have to say more than Saint's default UI,
feel free to integrate your pages directly into pages rendered by Saint.

Say you some very specific columns that are hard to define by Saint's Api.

No worry, simply write your html and create a new Saint tab for it.

*Example:* add a CRUD tab that will display given template

    saint.crud_tab :MyCustomWYSIWYG do
        view.render_partial :template_containing_my_custom_WYSIWYG
    end

You can also override the Saint's master tab, by setting tab name to :master.

*Example:* override master tab

    saint.crud_tab :master do
        view.render_partial :template_containing_my_custom_WYSIWYG
    end

Given block will receive back the current row and the pager,
so you can use row's data and pager build fully fledged tabs.

Given template is rendered inside running controller,
so it may call any controller action.

    class Page
        include Saint::Api
        http.map :page
        
        saint.model Model::Page

        saint.crud_tab :my_classy_column do |row|
            <<-HTML
            <form action="#{http.route(:my_classy_action, row.id)}" method="post">
            <textarea class="my_classy_rich_text_editor"><%== row.content -%></textarea>
            <input type="submit" value="save">
            </form>
            HTML
        end

        def my_classy_action row_id
            # do stuff and redirect to http.route(:edit, row_id)
        end
    end


###Confines

Prohibit create new items:

    saint.create false

Prohibit update items:

    saint.update false

Prohibit delete items:

    saint.delete false

###Callbacks

Callbacks will be executed before/after given ORM action(s).
If no actions given, callbacks will be executed before any action.

Available actions:

*  save - fires when new item created or existing item updated
*  delete - fires when an item deleted
*  destroy - fires when all items are deleted

*Example:* execute an callback after deleting an item:

    saint.after :delete do
        # some logic here
    end

*Example:* execute an callback before any action:

    saint.before do
        # some logic here
    end

Proc will receive back the managed row as first argument(except #destroy action)
and can update it accordingly.

Performed action will be passed as second argument.

Proc will be executed inside node instance,
so it will have access to http/view/node/saint api.


###Layouts

####Global lyouts
By default, Saint use an fieldset as columns layout.

Default layout for an text element looks like:

    <fieldset><legend>[label]</legend>[field]</fieldset>

Use *saint.column_layout* to render all columns using custom layout:

    saint.column_layout '<div class="column-layout">[label]: [field]</div>'

####Per column layout

Use custom layout for a specific column:

    saint.column :some_column, layout: '<div class="column-layout">[label]: [field]</div>'

Use default layout with custom style/class:

    saint.column :some_column, layout_style: 'width: 20%;'
    saint.column :some_another_column, layout_class: 'custom-column-layout'

###CSS

**Custom width/height for specific columns:**

    saint.column :some_column, width: 400, height: 200
    saint.column :some_another_column, width: '20%', height: '10%'

Numerical widht/height are used as pixels.

**Custom style/class for specific columns:**

    saint.column :some_column, css_style: 'width: 400px;'
    saint.column :some_another_column, css_class: 'custom-column-css-class'
