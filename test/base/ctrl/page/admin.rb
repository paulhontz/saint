module Ctrl
  class Page

    include Saint::OptsApi
    opts Ctrl::Options

    saint.model Model::Page

    saint.header :name, ', by #author.name', ', #children.count children'

    saint.ipp 10
    saint.order :id, :desc

    saint.grid do
      column :name do
        value do |val|
          summary? ? [val, row.author ? ', by %s' % row.author.name : nil].join : val
        end
      end
      column :label
    end

    saint.grid do
      column :meta_title, :text, width: '60%' do
        summary false
      end
      column :meta_description, :text, height: 400 do
        summary false
      end
      column :meta_keywords, :text do
        summary false
      end
    end

    saint.column :content, :rte

    saint.grid do
      column :active, :boolean
      column :color1, :checkbox do
        options ['red', 'green', 'blue']
      end
      column :color2, :select do
        options ['red', 'green', 'blue']
      end
      column :color3, :radio do
        options ['red', 'green', 'blue']
      end
    end

    #saint.has_n :menus, Model::Menu, Model::MenuPage do
    #  node Ctrl::Menu, true
    #  order :id, :desc
    #end
    #
    #saint.is_tree
    #
    #saint.belongs_to :author, Model::Author do
    #  node Ctrl::Author, true
    #  column :name
    #  column :email
    #  column :status, :boolean
    #end

    saint.filter :name
    saint.filter :active, :boolean
    
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

    saint.crud_tab :blah do
      'blah!'
    end

  end
end
