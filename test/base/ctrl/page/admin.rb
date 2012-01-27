module Ctrl
  class Page

    include Saint::OptsApi

    opts Ctrl::Options

    http.before do
    end

    saint.rb_wrapper

    saint.header :name, ', by #author.name'

    saint.order :id, :desc
    
    saint.grid do
      column :name
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
    saint.filter :active do
      type :select do
        {1 => 'Yes', 0 => 'No'}
      end
    end

    saint.has_n :menus, Model::Menu, Model::MenuPage do
      order :id, :desc
    end

    saint.is_tree

    saint.belongs_to :author, Model::Author do
      #readonly true
    end

    saint.filter :menu, Model::Menu, Model::MenuPage

    saint.filter :country_id, Model::Country do
      option_label '#name (#authors.count authors)'
    end

    saint.filter :author_id, Model::Author do
      multiple true
      option_label '#name (#pages.count pages)'
      depends_on :country_id
    end

    saint.filter :name do
      logic :like
    end

    saint.before do |item, action|
      item.callback_a_test = action
    end

    saint.after do |item, action|
      item.update callback_z_test: action
    end

  end
end
