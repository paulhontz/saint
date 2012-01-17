module Model
  class Author

    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :email, String

  end
end
