module Ctrl
  class Author

    saint.model Model::Author

    saint.column :name
    saint.column :email
    saint.column :password, type: :password

    saint.column :status, label: :Color, type: :select, multiple: true, options: ['red', 'green', 'blue'], width: 200

    saint.filter :name

    saint.header 'Authors', :name
    saint.menu.label saint.h

    saint.has_n :pages, Model::Page do
      ipp 1000
      column :name, label: 'Name / Author' do |val, scp, row|
        val && (val + ((author = row.author) ? ' (%s)' % author.name : ''))
      end
    end

    saint.belongs_to :country, Model::Country

  end
end
