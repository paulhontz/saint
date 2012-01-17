module Ctrl
  class Page

    include Saint::Api

    http.map :page

    saint.model Model::Page
  end
end
