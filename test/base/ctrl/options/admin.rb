module Ctrl
  class Options

    pool = Presto::Cache::MongoDB.new(MONGODB_CONN.db('saint-opts_pool'))
    saint.opts pool do
      opt :default_meta_title, default: 'SaintTest - default_meta_title'
      opt :default_meta_description, default: 'SaintTest - default_meta_description', type: :text
      opt :color, type: :select, options: ['red', 'blue']
    end
  end
end