module Ctrl
  class Page

    node.test do

      label 'Deleting'

      before do
      end

      after do
      end

      should 'delete a page via http' do

        page = saint.model.create name: "Some #{rand} Page"

        rsp = get
        t { rsp.body =~ /#{http.route :edit, page.id}/ }

        get :delete, page.id

        rsp = get
        t { rsp.body !=~/#{http.route :edit, page.id}/ }
        t { saint.model.count(id: page.id) == 0 }

        page.destroy! rescue nil
      end

    end
  end
end
