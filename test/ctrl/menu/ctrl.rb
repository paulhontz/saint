module Ctrl
  class Menu

    include Presto::Api
    include Saint::Api

    http.map :menu

  end
end
