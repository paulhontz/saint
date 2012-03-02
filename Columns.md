
By default, Saint will create a column for each property found on given model
(excluding ones of unsupported types as well as primary and foreign keys).

To ignore some of them, simply use `saint.ignore :column1, :column2, :etc`

Column type are inherited from property.

You can fine tune any automatically added column, or even add new ones.

For example, your model contains :content property.
Saint will create an textarea column, but you need an WYSIWYG editor for :content.
You simply need to override :content column setup:

    saint.column :content, :rte

Columns will be displayed in the order they found in given model.

Custom types supported by Saint:

Text Fields
---

###:rte

    saint.column :content, :rte

<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/page-rte.png" class="screenshot" />
</div>

###:plain

Will only display the value, without render any field.<br/>
Plain columns are not saved to db.

    saint.column :option, :plain


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/plain.png" class="screenshot" />
</div>

###:password

Creates two password fields - password and password confirmation.

    saint.column :content, :password


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/password.png" class="screenshot" />
</div>

Selectors
---

###:radio

    saint.column :status, :radio, options: {1 => :Active, 0 => :Suspended}
    # or
    saint.column :status, :radio do
        options 1 => :Active, 0 => :Suspended
    end


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/radio.png" class="screenshot" />
</div>

###:select

    saint.column :status, :select, options: {1 => :Active, 0 => :Suspended}
    # or
    saint.column :status, :select do
        options 1 => :Active, 0 => :Suspended
    end


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/select.png" class="screenshot" />
</div>

Use `multiple true` option to render an select field allowing to select multiple options.

Use `size: N` to define how much lines to display when :multiple set to true.

    saint.column :color, :select, size: 2, multiple: true, options: ['red', 'green', 'blue']
    # or
    saint.column :color, :select do
        size 2
        multiple true
        options 'red', 'green', 'blue'
    end


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/select-multiple.png" class="screenshot" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use `join_with 'some-str'` to override this.


###:checkbox

    saint.column :color, :checkbox, options: ['red', 'green', 'blue']
    # or
    saint.column :color, :checkbox do
        options 'red', 'green', 'blue'
    end


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/checkbox.png" class="screenshot" />
</div>

By default, Saint will join selected options with a coma when saved to db.<br/>
Use `join_with 'some-str'` to override this:

    saint.column :color, :checkbox, options: ['red', 'green', 'blue'], join_with: '/'
    # or
    saint.column :color, :checkbox do
        options 'red', 'green', 'blue'
        join_with '/'
    end


###:boolean

Renders an radio selector with 2 options: 1 => 'Yes' and 0 => 'No'

    saint.column :active, :boolean


<div class="screenshot-container">
<img src="http://saintrb.org/screenshots/columns/boolean.png" class="screenshot" />
</div>

Options
---

Options accepted by `saint.column` block:

###default

Sets default value for a column.<br/>
Accepts: [String, Integer]

    saint.column :some_column, default: 'some value'
    # or
    saint.column :some_column do
        default 'some value'
    end
    # for selectable columns, default option will be auto-selected.
    # on text columns, default text will be displayed for items with nil column value.


###options

Options to be used when rendering :checkbox, :radio and :select columns.<br/>
Accepts: [Hash, Array]

    saint.column :contact_me_by, :select, options: [:Phone, :Email]
    # HTML: <option value="Phone">Phone</option>
    #       <option value="Email">Email</option>

    saint.column :status, :radio, options: {1 => :Active, 0 => :Suspended}
    # HTML: <input type="radio" name="status" value="1" />Active
    #       <input type="radio" name="status" value="0" />Suspended
    
    saint.column :color, :checkbox, options: ['red', 'green', 'blue']
    # HTML: <input type="checkbox" name="color[]" value="red" />Red
    #       <input type="checkbox" name="color[]" value="green" />Green
    #       <input type="checkbox" name="color[]" value="blue" />Blue


###multiple

Instruct UI to render an selector allowing to select multiple options.<br/>
Used with :select type.<br/>
Accepts: [true]

###size

Allow UI to know how much lines multiple selector should have.<br/>
Used along with :select type and `multiple true` option.<br/>
Accepts: [Integer]

###join_with

The string to be used when joining multiple values.<br/>
Used with :select and :checkbox types.<br/>
Accepts: [String]

###label

By default label is generated from given column.<br/>
Use this option to have a different label.<br/>
Accepts: [String, Symbol]

    saint.column :name
    # Label to be used: Name

    saint.column :name, label: "Author's Name"
    # or
    saint.column :name do
        label "Author's Name"
    end
    # Label to be used: Author's Name


###summary

Instruct UI to exclude column from Summary pages.<br/>
Accepts: [false]

    saint.column :some_column, summary: false
    # or
    saint.column :some_column do
        summary false
    end


###crud

Instruct UI to exclude column from CRUD pages.<br/>
Accepts: [false]

    saint.column :some_column, crud: false
    # or
    saint.column :some_column do
        crud false
    end


###save

Instruct Saint to exclude column from attributes when saving item to db.<br/>
Accepts: [false]

    saint.column :some_column, save: false
    # or
    saint.column :some_column do
        save false
    end


###required

Instruct Saint to cancel save operation and return an error if field is empty.<br/>
Accepts: [true]

    saint.column :some_column, required: true
    # or
    saint.column :some_column do
        required true
    end


###value
---

Define a block that will modify current value depending on scope.<br/>
The block will receive current value as first argument.<br/>
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

