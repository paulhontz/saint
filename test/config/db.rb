class Cfg
  class Db

    DataMapper::Logger.new(STDOUT, :debug)

    yaml = YAML.load(File.read(Pfg.config('db.yml')))
    setup = yaml.values_at(:type, :user, :pass, :host, :name)
    DataMapper.setup(:default, "%s://%s:%s@%s/%s" % setup)

    DataMapper.repository(:default).adapter.resource_naming_convention = lambda do |value|
      DataMapper::Inflector.underscore(value).split('/').last
    end

  end
end
