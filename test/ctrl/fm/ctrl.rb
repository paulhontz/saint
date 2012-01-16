module Ctrl
  class Fm

    include Presto::Api
    include Saint::Api

    http.map :fm
  end
end
