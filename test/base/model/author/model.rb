module Model
  class Author
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :email, String
    property :password, String
    property :status, String
  end
end
