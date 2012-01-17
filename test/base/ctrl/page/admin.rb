module Ctrl
  class Page

    include Saint::OptsApi

    opts Ctrl::Options

    http.before do
    end

    saint.rb_wrapper

    saint.header 'Pages', :name, ' (#author.name)'

    saint.ipp 1000
    saint.grid do
      column :name, type: :string, rb_wrapper: false
      column :label, type: :string
    end

    saint.column :url, type: :string, rb_wrapper: false

    saint.grid do
      column :meta_title, type: :text
      column :meta_description, type: :text
      column :meta_keywords, type: :text
    end

    saint.column :content, type: :rte, height: '400px'

    saint.column :active, type: :boolean

    saint.filter :name
    saint.filter :content
    saint.filter :active do
      type :select do
        {1 => 'Yes', 0 => 'No'}
      end
    end

    saint.has_n :menus, Model::Menu, Model::MenuPage do
      order :id
      ipp 1000
    end

    saint.is_tree

    saint.belongs_to :author, Model::Author do
      #readonly true
    end

    saint.order :id

    saint.filter :menu, Model::Menu, Model::MenuPage

    saint.filter :country_id, Model::Country do
      option_label '#name (#authors.count authors)'
    end

    saint.filter :author_id, Model::Author do
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
