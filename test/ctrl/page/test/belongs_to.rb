module Ctrl
  class Page

    node.test :edit do

      label 'Testing belongs_to relationships'

      open do
        @var = 'val'
      end

      should 'belong to author' do

        author = Ctrl::Author.saint.model.create(name: "Some #{rand} Author")
        page = saint.model.create(name: "Some #{rand} Page")

        rsp, result = post_json :save, page.id, author_id: author.id
        t { result['status'] == page.id }

        rsp = get :edit, page.id
        t { rsp.body =~ /<input\s+name\s?=\s?["|']author_id["|']\s+value\s?=\s?["|']#{author.id}["|']/ }

        page.destroy
        author.destroy

      end

      should 'belong to parent' do

        parent = saint.model.create(name: "Some #{rand} Page")
        page = saint.model.create(name: "Some #{rand} Page")

        rsp, result = post_json :save, page.id, parent_id: parent.id
        t { result['status'] == page.id }

        rsp = get :edit, page.id
        t { rsp.body =~ /<input\s+name\s?=\s?["|']parent_id["|']\s+value\s?=\s?["|']#{parent.id}["|']/ }

        page.destroy
        parent.destroy
      end

    end
  end
end
