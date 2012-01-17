module Ctrl
  class Options

    include Saint::Api

    http.map :options
    saint.model Model::Options

  end
end
