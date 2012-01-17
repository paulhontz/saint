module Ctrl
  class Country

    saint.model Model::Country
    saint.column :name

    saint.filter :name

    saint.header 'Countries', :name
    saint.menu.label saint.h

    saint.has_n :authors, Model::Author do
      ipp 1000
    end

  end
end
