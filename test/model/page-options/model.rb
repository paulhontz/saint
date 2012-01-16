module Model
  class PageOptions

    include DataMapper::Resource

    property :id, Serial
    property :name, String, unique_index: true
    property :value, Text

  end
end
