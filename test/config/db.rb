#DataMapper::Model.raise_on_save_failure = true
#DataMapper::Logger.new(STDOUT, :debug)

DataMapper.setup :default, '%s://%s:%s@%s:%s/%s' % Cfg.db.values_at(:type, :user, :pass, :host, :port, :name)

DataMapper.repository(:default).adapter.resource_naming_convention = lambda do |value|
  DataMapper::Inflector.underscore(value).gsub('/', '_').sub(/^model_/, '')
end
