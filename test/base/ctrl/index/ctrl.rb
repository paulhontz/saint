module Ctrl
  class Index

    include Saint::Api

    http.map
    saint.menu.disabled

    def index
      view.render
    end

  end
end
