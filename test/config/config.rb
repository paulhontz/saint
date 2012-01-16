class Pfg

  class << self

    def root *paths
      [@root ||= File.expand_path('..', File.dirname(__FILE__))].concat(paths).join('/')
    end

    %w[config model ctrl view].each do |m|
      define_method m.to_sym do |*paths|
        [self.instance_variable_get(:"@#{m}") || self.instance_variable_set(:"@#{m}", root(m))].concat(paths).join('/')
      end
    end
  end

end

class Cfg

end

require Pfg.config 'db'
