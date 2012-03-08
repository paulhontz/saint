module Saint
  class FileServer

    DOCUMENT_ROOT = '/__saint-file_server__/'.freeze

    include Presto::Api

    http.map DOCUMENT_ROOT
    http.file_server '%s/static' % Saint.root do |env|
      env['PATH_INFO'] = env['PATH_INFO'].sub(/\.saint\-fs$/i, '')
      env
    end
    node.mount

    class Assets
      def initialize
        @path = '/'
      end

      def cd path
        @path = expand_path path
      end

      def js *paths
        buffer paths.map { |path| '<script type="text/javascript" src="%s"></script>' % url(path) }.join("\n")
      end

      def css *paths
        buffer paths.map { |path| '<link rel="stylesheet" href="%s"/>' % url(path) }.join("\n")
      end

      def img *paths
        buffer paths.map { |path| '<img src="%s"/>' % url(path) }.join("\n")
      end

      def output
        (@buffer||[]).join("\n")
      end

      private
      def url path
        Saint::FileServer[expand_path(path)]
      end

      def buffer str
        (@buffer ||= []) << str
        str
      end

      def expand_path path
        return @path = path if path == '/'
        levels = path.scan(Regexp.union('..')).size
        path = Presto::Utils.normalize_path(path).gsub(/^\/+/, '')
        return '%s/%s' % [@path, path] if levels == 0
        dirs = @path.split(/\/+/)
        [dirs[0, dirs.size - levels], path].join('/')
      end

    end

    class << self
      include Saint::Utils

      def [] path
        '%s%s.saint-fs' % [DOCUMENT_ROOT, normalize_path(path)]
      end

      def assets &proc
        instance = Assets.new
        if proc
          instance.instance_exec(&proc)
          return instance.output
        end
        instance
      end
    end

  end
end
