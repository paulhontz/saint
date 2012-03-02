module Model
  class Author
    include DataMapper::Resource

    property :id, Serial
    property :name, String
    property :email, String
    property :password, String
    property :date, Date
    property :date_time, DateTime
    property :time, Time
    property :status, Boolean
  end
end
