module Ctrl
  class Country

    saint.model Model::Country
    saint.column :name

    saint.filter :name

    saint.header 'Countries', :name
    saint.menu.label saint.h

    saint.order :id, :desc
    saint.has_n :authors, Model::Author do
      order :id, :desc
    end

  end
end
