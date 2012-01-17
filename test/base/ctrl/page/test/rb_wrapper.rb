module Ctrl
  class Page

    node.test do

      label 'Testing rb_wrapper'

      open, close = saint.rbw.wrapped_output.map { |t| ::Regexp.escape t }
      orig_open = ::Regexp.escape saint.rbw.map[:output_open][:orig]
      orig_close = ::Regexp.escape saint.rbw.map[:output_close][:orig]

      page = nil
      name = "Some #{rand} #{orig_open} snippet #{orig_close} Page"
      content = <<-HTML
      some content
      #{rand}
      #{orig_open} snippet #{orig_close}
      #{rand}
      HTML

      should 'create a page, then ...' do

        rsp, result = post_json :save, name: name, content: content
        page_id = result['status']
        t { page_id.is_a? Integer }
        t { page_id > 0 }

        page = saint.model.first(id: page_id)
        if t { page.respond_to? :content }

          should 'wrap/unwrap value of content column' do

            should 'have orig tags in db' do
              t { page.content =~ /#{orig_open}\s+snippet\s+#{orig_close}/ }
            end

            should 'have wrapped tags on crud page' do
              rsp = get :edit, page.id
              t { rsp.body =~ /#{open}\s+snippet\s+#{close}/ }
            end
          end

          should 'skip wrapping of name column' do
            page = saint.model.first(id: page.id)
            t { page.respond_to? :name }
            t { page.name !=~/#{open}\s+snippet\s+#{close}/ }
            t { page.name =~ /#{orig_open}\s+snippet\s+#{orig_close}/ }
            page.destroy
          end
        end
      end

    end
  end
end
