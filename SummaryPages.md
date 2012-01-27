
###Header

Defaulted to pluralized class name

To have a custom header for both Summary and CRUD pages, use `saint.header`:

    class Pages
        include Saint::Api

        saint.model Model::Page
        # header is(yet) "Pages"

        saint.header label: 'CMS Pages'
        # header now is "CMS Pages"
    end
{:lang='ruby'}

###Items per page

Defaulted to 10

    saint.items_per_page 100
    # or
    saint.ipp 100
{:lang='ruby'}

###Order

Defaulted to model's order

    saint.order :date, :desc
    saint.order :name, :asc
{:lang='ruby'}

###Text Filters

    saint.filter :name
    saint.filter :about
{:lang='ruby'}

*Note:* for filter to work, it should use a earlier defined column or association.

###Dropdown Filters

    saint.filter :active do
        type :select, options: {1 => 'Yes', 0 => 'No'}
    end
{:lang='ruby'}

[More on Filters](http://saintrb.org/Filters.md)

###Tabs

There are an single tab on Summary pages.

You can add more:

    saint.summary_tab :tab_name do
        # some html here
    end
{:lang='ruby'}

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
{:lang='ruby'}

To override Saint's master tab, use :master as tab name:

    saint.summary_tab :master do
        # some html here
    end
{:lang='ruby'}
