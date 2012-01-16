module Ctrl
  class Page

    node.test :index do

      should 'use hooks to update item' do
        ds = {
            name: "creating page via http - #{rand}",
            content: "SOME REALLY UNIQUE CONTENT - #{rand}",
        }

        rsp, result = post_json :save, ds
        page_id = result['status']
        t { page_id.is_a? Integer }
        t { page_id > 0 }

        if error = result['error']
          output error
        else

          output result['alert']

          page = saint.model.get(page_id)
          t { page.respond_to? :callback_a_test }
          t { page.callback_a_test == 'save' }
          t { page.callback_z_test == 'save' }

          page.destroy rescue nil

        end
      end

    end

  end
end
