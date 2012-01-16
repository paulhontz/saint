module Model
  class MenuPage

    belongs_to :menu, model: Menu, child_key: :menu_id
    belongs_to :page, model: Page, child_key: :page_id
  end
end
