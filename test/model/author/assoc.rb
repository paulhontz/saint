module Model
  class Author

    has n, :pages
    belongs_to :country, required: false
  end
end
