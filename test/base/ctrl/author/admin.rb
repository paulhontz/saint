module Ctrl
  class Author

    saint.model Model::Author

    saint.column :name
    saint.column :email
    saint.column :password, :password

    saint.column :status, :select do
      label :Color
      multiple true
      options ['red', 'green', 'blue']
      width 200
    end

    saint.filter :name

    saint.header :name
    saint.menu.label saint.h

    saint.order :id, :desc
    saint.has_n :pages, Model::Page do
      order :id, :desc
      column :name, label: 'Name / Author' do |val, scp, row|
        val && (val + ((author = row.author) ? ' (%s)' % author.name : ''))
      end
    end

    saint.belongs_to :country, Model::Country

  end
end
