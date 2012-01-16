module Model
  class Page

    is :tree
    belongs_to :author, required: false

    has n, :related_menus, model: MenuPage, child_key: :page_id
    has n, :menus, model: Menu, through: :related_menus
  end
end
