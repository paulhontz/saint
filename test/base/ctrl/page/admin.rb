module Ctrl
  class Page

    include Saint::OptsApi

    opts Ctrl::Options

    saint.rb_wrapper true

    saint.header :name, ', by #author.name'

    saint.order :id, :desc

    saint.grid do
      column :name do
        value do |val|
          summary? ? [val, row.author ? ', by %s' % row.author.name : nil].join : val
        end
      end
      column :label
    end

    saint.column :url

    saint.grid do
      column :meta_title, :text do
        summary false
      end
      column :meta_description, :text do
        summary false
      end
      column :meta_keywords, :text do
        summary false
      end
    end

    saint.column :content, :rte do
      height '400px'
    end

    saint.grid do
      column :active, :boolean
      column :color1, :checkbox do
        options ['red', 'green', 'blue']
      end
      column :color2, :select do
        options ['red', 'green', 'blue']
      end
      column :color3, :select do
        multiple true
        options ['red', 'green', 'blue']
      end
    end

    saint.filter :name
    saint.filter :content
    saint.filter :active, :boolean

    saint.has_n :menus, Model::Menu, Model::MenuPage do
      order :id, :desc
    end

    saint.is_tree

    saint.belongs_to :author, Model::Author do
      #readonly true
    end

    saint.filter :menu do
      model Model::Menu, through: Model::MenuPage
    end

    saint.filter :country_id do
      model Model::Country, label: '#name (#authors.count authors)'
    end

    saint.filter :author_id do
      multiple true
      model Model::Author, label: '#name (#pages.count pages)'
      depends_on :country_id
    end

    saint.filter :name

    saint.filter :author_name, :string do
      model Model::Author
      column :name
    end

    saint.before do |item, action|
      item.callback_a_test = action
    end

    saint.after do |item, action|
      item.update callback_z_test: action
    end

  end
end
