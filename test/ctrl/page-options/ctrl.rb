module Ctrl
  class PageOptions

    include Saint::Api

    http.map :page_options

    saint.model Model::PageOptions

    saint.opts do
      opt :default_meta_title
      opt :default_meta_description, default: 'SaintTest - default_meta_description', type: :text
    end

  end
end
