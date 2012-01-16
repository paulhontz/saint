Types
---

####Text fields

*   :string - renders an text field
*   :text - renders an textarea
*   :rte - renders an Rich Text Editor
*   :password - creates two password fields - password and password confirmation
*   :plain - only displays the value, without render any field. Plain columns are not saved to db.

####Selectors

*   :radio - renders an radio selector
*   :select - renders an drop-down selector. use !{multiple: true} to render an select field allowing to select multiple options.
*   :checkbox - renders an single checkbox
*   :boolean - renders an radio selector with 2 options: !{1 => 'Yes', 0 => 'No'}

*Examples:*

    saint.column :name
    # HTML: <input type="text" name="name" value="" />

    saint.column :about, type: :text
    # HTML: <textarea name="about"></textarea>

    saint.column :active, type: :boolean
    # HTML: <input type="radio" name="active" value="1">Yes
    #       <input type="radio" name="active" value="0">No

    saint.column :author_details, type: :plain do |value, scope, row|
        row && (author = row.author) && "#{author.name}, #{author.age} years old"
    end
    # output: John Doe, 20 years old
    # Note: this column wont be saved to db

Values
---

**Proc** - used to modify or set up a value to be used on CRUD and/or Summary pages.

Proc receives 3 arguments

*   :value - current value
*   :scope - :summary or :crud
*   :row - currently managed db item

Proc should return the value to be used.

*Example:* display book name with author's details on Summary pages

    saint.column :name do |value, scope, row|
        if scope.summary? && row
            value = '%s by <a href="%s">%s</a>' % [value, row.author.name, Author.http.route(:edit, author.id)]
        end
        value
    end
    # UI: Eloquent Ruby by <a href="/author/edit/1000">Russ Olsen</a>


**:default** - set default value for a column:

    saint.column :some_column, default: 'some value'
    # for selectable columns, default option will be auto-selected.
    # on text columns, default text will be displayed for items with nil column value.

**:options** - options to be used when rendering an drop-down selector:

    saint.column :contact_me_by, type: :select, options: [:Phone, :Email]
    # HTML: <option value="Phone">Phone</option>
    #       <option value="Email">Email</option>

    saint.column :status, type: :select, options: {1 => :Active, 2 => :Suspended}
    # HTML: <option value="1">Active</option>
    #       <option value="0">Suspended</option>

Instructions
---

**:summary => false** - instruct UI to exclude some column from Summary pages:

    saint.column :some_column, summary: false

**:crud => false** - instruct UI to exclude some column from CRUD pages:

    saint.column :some_column, crud: false

**:save => false** - instruct Saint to exclude column from attributes when saving item to db.

    saint.column :some_column, save: false

**:required => true** - instruct Saint to avoid save operation and return an error if field is empty:

    saint.column :some_column, required: true

**:multiple => true** - instruct UI to render an multiple select field:

    saint.column :some_column, multiple: true
