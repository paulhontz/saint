module Ctrl
  class Author

    node.test :edit do

      should 'attach/detach a page' do

        author = saint.model.create name: "Some #{rand} Author"
        page = Ctrl::Page.saint.model.create name: "Some #{rand} Page"
        relation = saint.has_n[:pages]

        should_have_an_attach_button = lambda do
          rsp = get :assoc__any__remote_items, relation.id, author.id, 0
          t { rsp.body =~ /<input[^>].*value\s?=\s?["|']attach["|'][^>].*assoc\/has_n\/update_remote_item\/+#{relation.id}\/+#{page.id}\/+#{author.id}/im }
        end

        should 'display attached page in "Select Pages to attach" tab' do

          should 'have an "attach" button, as page not attached yet', &should_have_an_attach_button

          should 'attach the page' do
            rsp, result = get_json :assoc__has_n__update_remote_item, relation.id, page.id, author.id, :create
            t { result['status'] == 1 }
            t { Ctrl::Page.saint.model.count(id: page.id, author: author) == 1 }
          end
        end

        should 'display attached page into "Attached Pages" tab' do

          should 'have an "detach" button' do
            rsp = get :assoc__any__remote_items, relation.id, author.id, 1
            t { rsp.body =~ /<input[^>].*value\s?=\s?["|']detach["|'][^>].*assoc\/+has_n\/+update_remote_item\/+#{relation.id}\/+#{page.id}\/+#{author.id}\/+delete/im }
          end

          should 'detach the page' do

            rsp, result = get_json :assoc__has_n__update_remote_item, relation.id, page.id, author.id, :delete
            t { result['status'] == 1 }

            should 'have an "attach" button', &should_have_an_attach_button
          end

        end

        page.destroy
        author.destroy
      end

    end
  end
end
