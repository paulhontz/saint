
###Header - defaulted to pluralized model name

To have a custom header for both Summary and CRUD pages, use *saint.header*:

    class Pages
        include Saint::Api

        saint.model Model::Page
        # header is(yet) "Pages"

        saint.header 'CMS Pages'
        # header now is "CMS Pages"
    end

###Items per page - defaulted to 10

    saint.items_per_page 100
    # or
    saint.ipp 100

###Order - defaulted to model's order

    saint.order :date, :desc
    saint.order :name, :asc

###Text Filters

    saint.column :name
    saint.column :about, type: :text

    saint.filter :name
    saint.filter :about

*Note:* for filter to work, it should use a earlier defined column or association.

###Dropdown Filters

    saint.column :active, type: :boolean

    saint.filter :active do
        type :select do
            {1 => 'Yes', 0 => 'No'}
        end
    end

[More on Filters](saint/blob/master/Filters.md)

###Tabs

There are an single tab on Summary pages.

You can add more:

    saint.summary_tab :tab_name do
        # some html here
    end

Given block will receive back the rows displayed on current page and the pager,
so you can display the rows the way you need.

*Example:* create a tab where rows are displayed in rounded containers

    saint.summary_tab :funny_style do |rows, pager|
        html = ''
        rows.each do |row|
            html << '<div class="rounded_container">%s</div>' % row.name
        end
        html
    end

To override Saint's master tab, use :master as tab name:

    saint.summary_tab :master do
        # some html here
    end
