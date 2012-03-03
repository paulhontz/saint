module Ctrl
  class Author

    saint.model Model::Author

    #saint.columns_ignored :status

    saint.column :password, :password

    #saint.filter :name, logic: 'like'
    #saint.filter :status, :boolean
    #saint.filter :date, :date
    #saint.filter :date_time, :date_time
    #saint.filter :time, :time

    saint.filters_ignored :password

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
    end

  end
end
