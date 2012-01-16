module Ctrl
  class Author

    include Presto::Api
    include Saint::Api

    http.map :author

  end
end
