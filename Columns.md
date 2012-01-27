Text fields
---

###:string

    saint.column :name

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-name.png" />
</div>

###:text

    saint.column :meta_title, :text

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-meta_title.png" />
</div>

###:rte

    saint.column :content, :rte

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/page-rte.png" />
</div>

###:plain

Will only display the value, without render any field.<br/>
Plain columns are not saved to db.

    saint.column :option, :plain

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/plain.png" />
</div>

###:password

Creates two password fields - password and password confirmation.

    saint.column :content, :password

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/password.png" />
</div>

Selectors
---

###:radio

    saint.column :status, :radio do
        options 1 => :Active, 0 => :Suspended
    end

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/radio.png" />
</div>

###:select

    saint.column :status, :select do
        options: 1 => :Active, 0 => :Suspended
    end

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/select.png" />
</div>

Use "multiple: true" option to render an select field allowing to select multiple options.<br/>
Use "size: N" to define how much lines to display when :multiple set to true.

    saint.column :color, :select do
        multiple true
        options ['red', 'green', 'blue']
    end

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/select-multiple.png" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use :join_with option to override this.


###:checkbox

    saint.column :color, :checkbox do
        options ['red', 'green', 'blue']
    end

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/checkbox.png" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use `join_with` option to override this:

    saint.column :color, :checkbox do
        options ['red', 'green', 'blue']
        join_with '/'
    end

###:boolean

Renders an radio selector with 2 options: 1 => 'Yes' and 0 => 'No'

    saint.column :active, :boolean

<div class="tutorial-example_picture-container">
<img src="http://saintrb.org/tutorial/columns/boolean.png" />
</div>

Options
---

Options accepted by `saint.column` block:

###default

Sets default value for a column.<br/>
Accepts: [String, Integer]

    saint.column :some_column do
        default 'some value'
    end
    # for selectable columns, default option will be auto-selected.
    # on text columns, default text will be displayed for items with nil column value.

###options

Options to be used when rendering :checkbox, :radio and :select columns.<br/>
Accepts: [Hash, Array]

    saint.column :contact_me_by, :select do
        options [:Phone, :Email]
    end
    # HTML: <option value="Phone">Phone</option>
    #       <option value="Email">Email</option>

    saint.column :status, :radio do
        options 1 => :Active, 0 => :Suspended
    end
    # HTML: <input type="radio" name="status" value="1" />Active
    #       <input type="radio" name="status" value="0" />Suspended
    
    saint.column :color, :checkbox do
        options ['red', 'green', 'blue']
    end
    # HTML: <input type="checkbox" name="color[]" value="red" />Red
    #       <input type="checkbox" name="color[]" value="green" />Green
    #       <input type="checkbox" name="color[]" value="blue" />Blue

###multiple

Instruct UI to render an selector allowing to select multiple options.<br/>
Used with ":type => :select" option.<br/>
Accepts: [true]

###size

Allow UI to know how much lines multiple selector should have.<br/>
Used with ":type => :select, :multiple => true" options.<br/>
Accepts: [Integer]

###join_with

The string to be used when joining multiple values.<br/>
Used with ":type => :select, :multiple => true" and ":type => :checkbox" options.<br/>
Accepts: [String]

###label

By default label is generated from given column.<br/>
Use this option to have a different label.<br/>
Accepts: [String, Symbol]

    saint.column :name
    # Label to be used: Name

    saint.column :name do
        label "Author's Name"
    end
    # Label to be used: Author's Name

###summary

Instruct UI to exclude column from Summary pages.<br/>
Accepts: [false]

    saint.column :some_column do
        summary false
    end

###crud

Instruct UI to exclude column from CRUD pages.<br/>
Accepts: [false]

    saint.column :some_column do
        crud false
    end

###save

Instruct Saint to exclude column from attributes when saving item to db.<br/>
Accepts: [false]

    saint.column :some_column do
        save false
    end

###required

Instruct Saint to cancel save operation and return an error if field is empty.<br/>
Accepts: [true]

    saint.column :some_column do
        required true
    end


###value
---

Define a block that will modify current value depending on scope.\\
The block will receive current value as first argument.\\
Current value will be set to value returned by block.

Methods available inside block:

*   summary? - true when column shown on Summary pages
*   crud? - true when column shown on CRUD pages
*   row - current row, from which column value are extracted
*   scope - one of :summary or :crud

So, if we want to prefix the author's name with Mr., we simply do like this:

    saint.column :name do
        value do |value|
            'Mr. %s' % value
        end
    end

Lets say we want to prefix the author's name with Mr. only on Summary pages:

    saint.column :name do
        value do |value|
            summary? ? 'Mr. %s' % value : value
        end
    end

Lets say we want to prefix the author's name with Mr. for men,  Ms. for women and empty for unknown:

    saint.column :name do
        value do |value|
            prefix = nil
            prefix = 'Mr.' if row.gender == 'male'
            prefix = 'Ms.' if row.gender == 'female'
            '%s %s' % [prefix, value]
        end
    end
