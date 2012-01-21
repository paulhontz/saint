Text fields
---

###:string

    saint.column :name

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-name.png" />
</div>

###:text

    saint.column :meta_title, type: :text

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-meta_title.png" />
</div>

###:rte

    saint.column :content, type: :rte

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-rte.png" />
</div>

###:plain

Will only display the value, without render any field.<br/>
Plain columns are not saved to db.

    saint.column :option, type: :plain

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/plain.png" />
</div>

###:password

Creates two password fields - password and password confirmation.

    saint.column :content, type: :password

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/password.png" />
</div>

Selectors
---

###:radio

    saint.column :status, type: :radio, options: {1 => :Active, 0 => :Suspended}

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/radio.png" />
</div>

###:select

    saint.column :status, type: :select, options: {1 => :Active, 0 => :Suspended}

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/select.png" />
</div>

Use "multiple: true" option to render an select field allowing to select multiple options.<br/>
Use "size: N" to define how much lines to display when :multiple set to true.

    saint.column :color, type: :select, multiple: true, options: ['red', 'green', 'blue']

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/select-multiple.png" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use :join_with option to override this.


###:checkbox

    saint.column :color, type: :checkbox, options: ['red', 'green', 'blue']

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/checkbox.png" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use :join_with option to override this:

    saint.column :color, type: :checkbox, join_with: '/', options: ['red', 'green', 'blue']

###:boolean

Renders an radio selector with 2 options: !{1 => 'Yes', 0 => 'No'}

    saint.column :active, type: :boolean

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/boolean.png" />
</div>

Options
---

**saint.column** also accepts an set of options.

###:default

Sets default value for a column.<br/>
Accepts: [String, Integer]

    saint.column :some_column, default: 'some value'
    # for selectable columns, default option will be auto-selected.
    # on text columns, default text will be displayed for items with nil column value.

###:options

Options to be used when rendering :checkbox, :radio and :select columns.<br/>
Accepts: [Hash, Array]

    saint.column :contact_me_by, type: :select, options: [:Phone, :Email]
    # HTML: <option value="Phone">Phone</option>
    #       <option value="Email">Email</option>

    saint.column :status, type: :radio, options: {1 => :Active, 0 => :Suspended}
    # HTML: <input type="radio" name="status" value="1" />Active
    #       <input type="radio" name="status" value="0" />Suspended
    
    saint.column :color, type: :checkbox, options: ['red', 'green', 'blue']
    # HTML: <input type="checkbox" name="color[]" value="red" />Red
    #       <input type="checkbox" name="color[]" value="green" />Green
    #       <input type="checkbox" name="color[]" value="blue" />Blue

###:multiple

Instruct UI to render an selector allowing to select multiple options.<br/>
Used with ":type => :select" option.<br/>
Accepts: [true]

###:size

Allow UI to know how much lines multiple selector should have.<br/>
Used with ":type => :select, :multiple => true" options.<br/>
Accepts: [Integer]

###:join_with

The string to be used when joining multiple values.<br/>
Used with ":type => :select, :multiple => true" and ":type => :checkbox" options.<br/>
Accepts: [String]

###:label

By default label is generated from given column.<br/>
Use this option to have a different label.<br/>
Accepts: [String, Symbol]

    saint.column :name
    # Label to be used: Name

    saint.column :name, label: "Author's Name"
    # Label to be used: Author's Name

###:summary

Instruct UI to exclude column from Summary pages.<br/>
Accepts: [false]

    saint.column :some_column, summary: false

###:crud

Instruct UI to exclude column from CRUD pages.<br/>
Accepts: [false]

    saint.column :some_column, crud: false

###:save

Instruct Saint to exclude column from attributes when saving item to db.<br/>
Accepts: [false]

    saint.column :some_column, save: false

###:required

Instruct Saint to cancel save operation and return an error if field is empty.<br/>
Accepts: [true]

    saint.column :some_column, required: true


Blocks
---

**saint.column** also accepts a block.

When a column that have defined a block are rendered,
the given block will be called with 3 arguments:

*   value - the current column value
*   scope - :summary or :crud
*   row - the model item currently managed

The result returned by block will be displayed as column value.

So, if we want to prefix the author's name with Mr., we simply do like this:

    saint.column :name do |value|
        'Mr. %s' % value
    end

**Second argument** allow us to have different values on Summary and on CRUD pages.

Lets say we want to prefix the author's name with Mr. only on Summary pages:

    saint.column :name do |value, scope|
        scope == :summary ? 'Mr. %s' % value : value
        # or
        scope.summary? ? 'Mr. %s' % value : value
    end

**Third argument** giving access to currently displayed row.

Lets say we want to prefix the author's name with Mr. for men,  Ms. for women and empty for unknown:

    saint.column :name do |value, scope, row|
        prefix = nil
        prefix = 'Mr.' if row.gender == 'male'
        prefix = 'Ms.' if row.gender == 'female'
        '%s %s' % [prefix, value]
    end
