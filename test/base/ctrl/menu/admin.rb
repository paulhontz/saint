module Ctrl
  class Menu

    saint.model Model::Menu
    
    saint.column :name
    saint.column :body, :text

    saint.filter :name
    saint.filter :body

    saint.header 'Menus', :name
    saint.menu.label saint.h

    saint.order :id, :desc
    saint.has_n :pages, Model::Page, Model::MenuPage do
      order :id, :desc
      remote_node Ctrl::Page
    end
  end
end
