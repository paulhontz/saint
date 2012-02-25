module Saint
  module FileManager

    class Setup

      include Presto::Utils
      include Saint::Inflector

      def initialize node, &proc
        @node = node
        self.instance_exec &proc
      end

      # multiple roots supported.
      # Saint will create a controller for each root.
      def root path, opts = {}

        node = @node
        path = rootify_url(path)
        unless File.directory?(path)
          puts 'Creating %s ...' % path
          FileUtils.mkdir_p path
        end
        label = (opts[:label] || File.basename(path)).to_s
        name = classify(opts[:name] || label.gsub(/[^\w|\d]/i, ''))
        file_server = @node.const_set classify('%sFileServer' % name), Class.new
        file_server.class_exec do

          include Presto::Api
          http.map node.http.route('/__saint-file_manager__/%s/' % http.escape_path(label.downcase))
          http.file_server path do |env|
            env["PATH_INFO"] = env["PATH_INFO"].sub(/\.saint\-fm$/i, '')
            env
          end

          def self.[] path
            Presto::Utils.normalize_path '%s/%s.%s' % [http.route, path, 'saint-fm']
          end
        end
        roots[label] = Struct.
            new(:path, :name, :label, :file_server).
            new(path, name, label, file_server)
        file_server
      end

      def roots
        @roots ||= Hash.new
      end

    end

    class Helper

      attr_reader :editable_files, :viewable_files, :readonly_files

      def initialize

        @editable_files = {
            'html' => 'html', 'htm' => 'html', 'xhtml' => 'html', 'rhtml' => 'html',
            'erb' => 'html', 'txt' => 'edit', 'log' => 'edit', 'php' => 'edit',
            'php4' => 'php', 'phps' => 'php', 'css' => 'edit', 'csv' => 'edit',
            'js' => 'edit', 'xml' => 'html', 'sql' => 'edit', 'asp' => 'edit',
            'jsp' => 'edit', 'rss' => 'rss', 'cfg' => 'edit', 'ini' => 'edit',
            'py' => 'py', 'pl' => 'pl', 'rb' => 'rb', 'ru' => 'rb', 'java' => 'java',
            'dtd' => 'html', 'cs' => 'edit', 'cpp' => 'edit', 'class' => 'edit',
            'c' => 'edit', 'tmp' => 'txt', 'm3u' => 'edit', 'cgi' => 'edit',
            'makefile' => 'edit', 'gemfile' => 'edit', 'readme' => 'edit',
            'changelog' => 'edit', 'license' => 'edit', 'md' => 'edit',
        }

        @viewable_files = {
            'bmp' => 'jpg', 'gif' => 'jpg', 'jpg' => 'jpg', 'jpeg' => 'jpg',
            'png' => 'png', 'tif' => 'jpg', 'tiff' => 'jpg', 'svg' => 'svg',
        }

        @readonly_files = {
            'image' => '',
            'psd' => nil, 'fla' => nil, 'rtf' => nil, 'doc' => nil, 'docx' => 'doc',
            'dat' => nil, 'pps' => nil, 'ppt' => nil, 'pptx' => 'ppt', 'sdf' => nil,
            'vcf' => nil, 'xlr' => nil, 'xls' => nil, 'xlsx' => 'xls', 'efx' => nil,
            'key' => nil, 'aif' => nil, 'iff' => nil, 'm4a' => nil, 'mid' => nil,
            'mp3' => nil, 'mpa' => nil, 'ra' => nil, 'wav' => nil, 'wma' => nil,
            '3g2' => nil, '3gp' => nil, 'asf' => nil, 'asx' => nil, 'avi' => nil,
            'flv' => nil, 'mov' => nil, 'mp4' => nil, 'mpg' => nil, 'rm' => nil,
            'swf' => nil, 'vob' => nil, 'wmv' => nil, 'ai' => nil, 'drw' => nil,
            'eps' => nil, 'ps' => nil, 'app' => nil, 'bat' => nil, 'com' => nil,
            'exe' => nil, 'jar' => nil, 'vb' => nil, 'wsf' => nil, 'cab' => nil,
            'dll' => nil, 'sys' => nil, '7z' => nil, 'deb' => nil, 'gz' => nil,
            'pkg' => nil, 'rar' => nil, 'rpm' => nil, 'sit' => nil, 'sitx' => 'sit',
            'tar' => nil, 'gz' => nil, 'zip' => 'zip', 'zipx' => 'zip', 'dmg' => nil,
            'iso' => nil, 'vcd' => nil,
        }
      end

      def file file
        filename = ::File.basename(file).downcase
        ext = ::File.extname(file).to_s.sub(/^\./, '').downcase
        map = editable_files.merge(viewable_files).merge(readonly_files)
        file = Hash.new
        file[:icon] = icon(map[ext] || 'file')
        %w[ editable viewable readonly ].each do |state|
          map = self.send(:"#{state}_files")
          file[:"#{state}?"] = map.has_key?(ext) || map.has_key?(filename)
        end
        file
      end

      def icon path
        Saint::FileServer['vendor/icons/Oxygen/16/%s.%s' % [path, 'png']]
      end

      def size file, human = nil
        size = File.size?(file) || Rack::Utils.bytesize(File.read(file))
        human ? Saint::Utils.number_to_human_size(size) : size
      end

      def geometry file
        image = MiniMagick::Image.open(file)
        [image[:width], image[:height]]
      end

      def resize w, h, src_file, dst_file = nil
        error = nil
        if w + h > 0
          begin
            args = dst_file ? [:open, src_file] : [:new, src_file]
            image = MiniMagick::Image.send *args
            if w > 0
              if h > 0
                geometry = '%sx%s!' % [w, h]
              else
                geometry = w.to_s
              end
            else
              geometry = 'x%s' % h
            end
            image.resize geometry
            image.write(dst_file) if dst_file
          rescue => e
            error = e
          end
        else
          error = 'please specify width and/or height'
        end
        return error if error
        true
      end

    end
  end
end
