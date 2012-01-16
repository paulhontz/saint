module Ctrl
  class Menu

    saint.column :name, type: :string
    saint.column :body, type: :text

    saint.filter :name
    saint.filter :body

    saint.header 'Menus', :name
    saint.menu.label saint.h

    saint.ipp 1000

    saint.has_n :pages, Model::Page, Model::MenuPage do
      ipp 1000
      remote_node Ctrl::Page
    end
  end
end
