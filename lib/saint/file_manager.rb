module Saint
  module FileManager

    EDIT_MAX_SIZE = 5_242_880.freeze
    UPLOAD_MAX_SIZE = 10_485_760.freeze

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
            'c' => 'edit', 'tmp' => 'edit', 'm3u' => 'edit', 'cgi' => 'edit',
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
        name = ::File.basename(file)
        ext = ::File.extname(file).to_s.sub(/^\./, '').downcase
        map = editable_files.merge(viewable_files).merge(readonly_files)
        file = {
            name: name,
            icon: icon(map[ext] || 'file'),
        }
        %w[ editable viewable readonly ].each do |state|
          map = self.send(:"#{state}_files")
          file[:"#{state}?"] = map.has_key?(ext) || map.has_key?(name.downcase)
        end
        file
      end

      def icon path
        Saint::FileServer['vendor/icons/Oxygen/16/%s.%s' % [path, 'png']]
      end

      def size file, human = nil
        size = ::File.size?(file) || ::Rack::Utils.bytesize(::File.read(file))
        human ? Saint::Utils.number_to_human_size(size) : size
      end

      def geometry file
        begin
          image = MiniMagick::Image.open(file)
          [image[:width], image[:height]]
        rescue => e
          @errors = e
          Saint::Utils.saint_view(self).render_partial 'error'
        end
      end

      def resize w, h, src_file, dst_file = nil
        error = nil
        if w + h > 0
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
        else
          error = 'please specify width and/or height'
        end
        return error if error
        true
      end

    end
  end
end
