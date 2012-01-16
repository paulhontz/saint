require '../init'

1.upto(100) do |n|
  Model::Page.create(name: "page Nr#{n}")
  Model::Author.create(name: "author Nr#{n}")
end
