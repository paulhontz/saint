module Ctrl
  class Page

    node.test :edit do

      label 'Testing has_n relations'

      should 'have and belong to N menus through MenuPage model' do

        page_id, menu_id = nil, nil
        should 'create a page' do
          rsp, result = post_json :save, name: "Some #{rand} Page"
          page_id = result['status']
          t { page_id.is_a? Integer }
          t { page_id > 0 }
        end

        should 'create an menu' do
          rsp, result = post_json Ctrl::Menu, :save, name: "Some #{rand} Menu"
          menu_id = result['status']
          t { menu_id.is_a? Integer }
          t { page_id > 0 }
        end

        relation = saint.has_n[:menus]
        should_have_an_attach_button = lambda do
          rsp = get :assoc__any__remote_items, relation.id, page_id, 0
          t { rsp.body =~ /<input[^>].*value\s?=\s?["|']attach["|'][^>].*assoc\/has_n\/update_through_model\/+#{relation.id}\/+#{menu_id}\/+#{page_id}\/+create/im }
        end

        should 'display created menu in "Select Menus to attach" tab' do
          should 'have "attach" button', &should_have_an_attach_button
        end

        should 'attach the page to created menu' do
          rsp, result = post_json :assoc__has_n__update_through_model, relation.id, menu_id, page_id, :create
          t { result['status'] == 1 }
        end

        should 'detach menu from page' do

          rsp, result = post_json :assoc__has_n__update_through_model, relation.id, menu_id, page_id, :delete
          t { result['status'] == 1 }

          should 'have "attach" button', &should_have_an_attach_button

        end

        should 'delete created page' do
          post :delete, page_id
          t { saint.model.count(id: page_id) == 0 }
        end

        should 'delete created menu' do
          post Ctrl::Menu, :delete, menu_id
          t { Ctrl::Menu.saint.model.count(id: menu_id) == 0 }
        end

      end

    end
  end
end
