module Ctrl
  class Index

    include Saint::Api

    http.map :dashboard
    saint.header label: :Dashboard
    saint.menu.position 1_000
    saint.dashboard false

    def index
      saint.dashboard
    end

  end
end
