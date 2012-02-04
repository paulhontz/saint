module Ctrl
  class Author

    saint.model Model::Author

    saint.column :name
    saint.column :email
    saint.column :password, :password

    saint.column :status, :boolean

    saint.filter :name, logic: 'like'
    saint.filter :status, :boolean

    saint.header :name
    saint.menu.label saint.h

    saint.order :id, :desc
    saint.has_n :pages, Model::Page do
      order :id, :desc
      column :name do
        label 'Name / Author'
        value do |val|
          val && (val + ((author = row.author) ? ' (%s)' % author.name : ''))
        end
      end
    end

    saint.belongs_to :country, Model::Country

  end
end
