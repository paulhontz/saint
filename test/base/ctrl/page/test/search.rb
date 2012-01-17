module Ctrl
  class Page

    node.test :index do

      label 'Searching'

      open do
        @page = saint.model.create name: "some #{rand} page"
      end

      close do
        @page.destroy!
      end

      should 'create a page and display it in search results' do
        rsp = get 'saint-filters' => {name: @page.name}
        t { rsp.status == 200 }
        t { rsp.body =~ /#{@page.name}/ }
      end

    end

  end
end
