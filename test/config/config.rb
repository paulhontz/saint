class Pfg

  class << self

    def root
      @root ||= File.expand_path('..', File.dirname(__FILE__)) + '/'
    end

    %w[config base public].each do |m|
      define_method m.to_sym do
        Pfg.root / m / ''
      end
    end

    %w[model view ctrl].each do |m|
      define_method m.to_sym do
        Pfg.base / m / ''
      end
    end

    def tmp
      root / :tmp / ''
    end
  end
  Pfg.root
end

class Cfg

  class << self
    def env
      'prod'
    end

    def dev?
      env == 'dev'
    end

    def prod?
      env == 'prod'
    end

    YAML.load(File.read(Pfg.config / 'config.yml')).select { |e, v| e.to_s == Cfg.env }.each_value do |opts|
      opts.each_pair do |var, val|
        define_method var do
          instance_variable_get("@#{var}") || instance_variable_set("@#{var}", val)
        end
      end
    end
  end
end
