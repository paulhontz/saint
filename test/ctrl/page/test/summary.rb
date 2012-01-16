module Ctrl
  class Page

    node.test :index do

      label "Testing Summary Page"

      should 'show the page on summary page' do

        page = saint.model.create name: "Some #{rand} Page"

        rsp = get
        t { rsp.status == 200 }
        t { rsp.body =~ /#{page.name}/ }

        page.destroy
      end

      should 'have name and content columns in filters' do
        rsp = get
        t { rsp.status == 200 }
        t { rsp.body =~ /saint-filters\[name\]/ }
        t { rsp.body =~ /saint-filters\[content\]/ }
      end

    end
  end
end
