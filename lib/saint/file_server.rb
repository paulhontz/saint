module Saint
  class FileServer

    DOCUMENT_ROOT = '/__saint-file_server__/'

    include Presto::Api
    http.map DOCUMENT_ROOT
    http.file_server '%s/static' % Saint.root do |env|
      env['PATH_INFO'] = env['PATH_INFO'].sub(/\.saint\-fs$/i, '')
      env
    end
    node.mount

    def self.[] key
      [DOCUMENT_ROOT, key, '.saint-fs'].join
    end

  end
end
