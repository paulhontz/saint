module Ctrl
  class Author

    saint.model Model::Author

    #saint.menu.parent Ctrl::Country

    saint.column :name
    saint.column :email
    saint.column :password, :password

    saint.column :status, :boolean

    saint.filter :name, logic: 'like'
    saint.filter :status, :boolean

    saint.header :name

    saint.order :id, :desc
    saint.has_n :pages, Model::Page do
      node Ctrl::Page, true
      order :id, :desc
      column :name do
        label 'Name / Author'
        value do |val|
          val && (val + ((author = row.author) ? ' (%s)' % author.name : ''))
        end
      end
    end

    saint.belongs_to :country, Model::Country do
      node Ctrl::Country, true
      # other setup
    end

  end
end
