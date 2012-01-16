module Ctrl
  class Page

    include Presto::Api
    include Saint::Api

    http.map :page

    saint.model Model::Page
  end
end
