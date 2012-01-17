module Model
  class Menu

    has n, :related_pages, model: MenuPage, child_key: :menu_id
    has n, :pages, model: Page, through: :related_pages
  end
end
