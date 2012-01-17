module Model
  class Menu

    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :body, Text

  end
end
