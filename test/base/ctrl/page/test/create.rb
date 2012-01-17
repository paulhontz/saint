module Ctrl
  class Page

    node.test :edit do

      label 'Creating and Removing pages via http'

      should 'create a page and display it on Edit page, then remove it' do

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

          should 'return correct fields and values on edit page' do
            rsp = get :edit, page_id
            t { rsp.body =~ /<input[^>].*name\s?=\s?["|']name["|'].*/i }
            t { rsp.body =~ /<input.*value\s?=\s?["|']#{ds[:name]}["|'].*/i }
            t { rsp.body =~ /<textarea[^\>].*>#{ds[:content]}<\/textarea>/i }
          end

          should 'remove the page' do
            get :delete, page_id

            should 'missing from summary page' do
              rsp = get
              t { rsp.body !=~ /#{http.route(:edit, page_id)}/ }
            end
          end

        end

      end

    end
  end
end
