module Saint
  class FmExtender

    include Saint::Utils
    include Saint::Inflector

    attr_reader :roots

    def initialize node, opts = {}, &proc
      @node, @opts, @roots = node, opts, Array.new
      self.instance_exec &proc
      unless @node.respond_to?(:index)
        root = @roots.first
        @node.class_exec { http.before { http.redirect root.http.route } }
      end
    end

    def root root, label = nil

      root = normalize_path root
      label ||= File.basename(root)
      node, host = @node, self

      raise '"%s" should be a directory' % root unless File.directory?(root)

      fm_class = classify(label)
      fm = node.const_set fm_class, Class.new
      @roots << fm

      fs = fm.const_set :FileServer, Class.new
      fm.class_exec do
        include Saint::Api
        include Saint::Utils
        http.map node.http.route(fm_class)
        saint.header label: label
        saint.menu.parent node
      end

      fs.class_exec do

        include Presto::Api
        http.map fm.http.route('__file_server__')
        http.file_server root do |env|
          env['PATH_INFO'] = env['PATH_INFO'].sub(/\.saint\-fs$/, '')
        end

        def self.[] path
          '%s/%s.saint-fs' % [http.route, Presto::Utils.normalize_path(path, false, false)]
        end
      end

      fm.class_exec do
        define_method :roots do
          host.roots
        end

        define_singleton_method :root do
          root
        end

        define_method :root do
          root
        end

        define_singleton_method :label do
          fm_class
        end

        define_method :label do
          fm_class
        end
      end
      extend fm
    end

    def extend node

      node.class_exec do

        http.before do
          @helper = Saint::FileManager::Helper.new
        end

        http.before :index, :create, :rename, :resize, :delete, :search, :copy do |path = nil|
          @encoded_path = path
          @query_string = Hash.new
          if (search_query = http.params['q']) && search_query.size > 1
            @query_string[:q] = search_query
          end
          @path = path ? normalize_path(decode_path(path), false, false) : ''
          @__meta_title__ = 'FileManager | %s | %s' % [saint.label, @path]
        end

        def index path = nil
          @active_dir, @active_file = nil, active_file?
          if @active_file
            view = :file
          else
            view = :index
            scan
            @path.split('/').each { |dir| scan dir }
          end
          saint_view.render_layout saint_view.render_partial('fm/%s' % view)
        end

        def create path = nil

          name, type = path_related_params 'name', 'type'
          return unless name && type
          node = File.join(root, @path, name)

          jsonify do
            encoded_path = encode_path(File.join(@path, name))
            if type == 'folder'
              FileUtils.mkdir node
              route = [encoded_path]
            else
              FileUtils.touch node
              route = [encode_path(@path), {file: encoded_path}]
            end
            route
          end
        end

        def rename path = nil

          path, name = path_related_params 'path', 'name'
          return unless path && name

          old_path = File.join(root, path)
          path = File.dirname(path)
          new_path = File.join(root, path, name)

          jsonify do
            raise '"%s" already exists' % name if File.file?(new_path) || File.directory?(new_path)
            FileUtils.mv old_path, new_path
            route = [encode_path(File.join(path, name))]
            route = [encode_path(@path)] << {file: encode_path(File.join(path, name))} if File.file?(new_path)
            route
          end
        end

        def delete path = nil

          path = path_related_params 'path'
          return unless path

          jsonify do
            FileUtils.remove_entry_secure File.join(root, path)
            [encode_path(File.directory?(File.join root, @path) ? @path : File.dirname(path))]
          end
        end

        def move

          src, dst, current = path_related_params 'src', 'dst', 'current'
          return unless src && dst && current

          jsonify do
            ::FileUtils.mv(::File.join(root, src), ::File.join(root, dst))
            current_path = ::File.join(root, current)
            [encode_path(File.file?(current_path) || ::File.directory?(current_path) ? current : dst)]
          end
        end

        def resize path = nil

          path, name = path_related_params 'path', 'name'
          return unless path && name

          jsonify do

            @helper.resize *[
                http.params.values_at('width', 'height').map { |v| v.to_i },
                File.join(root, path),
                File.join(root, File.dirname(path), name),
            ].flatten

            [encode_path(@path)] << {file: encode_path(File.join(File.dirname(path), name))}
          end
        end

        def upload

          path, name = path_related_params 'path', 'name'
          return unless path && name

          begin
            FileUtils.mv(http.params['file'][:tempfile], ::File.join(root, path, name))
          rescue => e
            @errors = e
            return saint_view.render_partial('error')
          end
          1
        end

        def download

          path = path_related_params 'file'
          return unless path

          file = File.basename(path)
          fs = Rack::File.new File.join(root, File.dirname(path))
          response = fs.call(http.env.merge('PATH_INFO' => file))
          response[1].update 'Content-Disposition' => "attachment; filename=#{file}"
          http.halt response
        end

        def save

          file = path_related_params 'file'
          return unless file

          jsonify do
            ::File.open(::File.join(root, file), 'w:utf-8') do |f|
              f << Saint::Utils.normalize_string(http.post_params['content'])
            end
            {status: 1, message: 'File successfully saved'}
          end
        end

        def copy path = nil
          path, name = path_related_params 'path', 'name'
          return unless path && name

          jsonify do
            rel_path = File.join File.dirname(path), name
            full_path = File.join root, rel_path
            conflicting_file = File.file?(full_path) ? rel_path : nil
            if File.directory?(full_path) && File.file?(File.join(full_path, File.basename(path)))
              conflicting_file = File.join rel_path, File.basename(path)
            end
            raise '"%s" file already exists' % conflicting_file if conflicting_file
            FileUtils.cp File.join(root, path), full_path
            [encode_path(@path)] << {file: encode_path(rel_path)}
          end
        end

        def search
          files = Array.new
          Find.find(root).select { |p| ::File.file?(p) }.each do |p|
            if ::File.basename(p) =~ /#{Regexp.escape http.params['query']}/
              file = @helper.file(p).merge(path: p.sub(root, ''))
              file[:path_encoded] = encode_path(file[:path])
              files << file
            end
          end
          saint_view.render_partial 'fm/search', files: files
        end

        def read_file
          file = path_related_params 'file'
          return unless file
          file = decode_path file
          return unless ::File.file?(full_path = ::File.join(root, file))
          content, @errors = nil
          if @helper.size(full_path) > Saint::FileManager::MAX_FILE_SIZE
            @errors = 'Sorry, files bigger than %s are not editable.' % number_to_human_size(Saint::FileManager::MAX_FILE_SIZE)
          else
            begin
              content = Saint::Utils.normalize_string ::File.open(full_path, 'r:utf-8').read
            rescue => e
              @errors = 'Unable to read file: %s' % e.message
            end
          end
          response = {status: 1, content: content}
          response = {status: 0, message: saint_view.render_partial('error')} if @errors
          response.to_json
        end

        private
        def active_file?

          file = path_related_params 'file'
          return unless file
          file = decode_path file
          return unless ::File.file?(full_path = ::File.join(root, file))

          node = @helper.file(full_path).update(
              path: file,
              name: ::File.basename(file),
              size: @helper.size(full_path),
              uniq: 'saint-fm-file-' << Digest::MD5.hexdigest(full_path),
              :file? => true
          )
          node[:path_encoded] = encode_path(node[:path])
          if node[:viewable?]
            node[:url] = FileServer[file]
            node[:geometry] = @helper.geometry(full_path)
          end
          node
        end

        def scan dir = nil

          @dirs ||= Array.new
          @current_path ||= Array.new
          dir_path = File.join(*@current_path, dir||'')
          dir_full_path = File.join(root, dir_path, '')
          return unless File.directory?(dir_full_path)
          @current_path << dir if dir
          @root_folder = dir.nil? ? {path: '/', label: 'Root'} : false

          nodes = {dirs: [], files: []}
          ls(dir_full_path).each do |n|

            name = File.basename(n)

            node = Hash.new
            node[:dir] = dir_path
            node[:name] = name
            node[:path] = File.join([dir_path, name].select { |c| c.size > 0 })
            node[:path_encoded] = encode_path(node[:path])
            node[:uniq] = 'saint-fm-%s-' << Digest::MD5.hexdigest(node[:path])

            if File.directory?(n)

              node[:dir?] = true
              node[:icon] = @helper.icon('folder')
              node[:uniq] = node[:uniq] % 'dir'

              if @path =~ /^#{Regexp.escape node[:path]}\//
                node[:selected_dir?] = true
              end
              if @path == node[:path]
                @active_dir, node[:active_dir?] = node, true
              end

              nodes[:dirs] << node

            else

              node.update(@helper.file(n))
              node[:file?] = true
              node[:uniq] = node[:uniq] % 'file'
              node[:size] = @helper.size(n, true)

              nodes[:files] << node
            end
          end
          @dirs << {name: dir, path: dir_path, nodes: nodes}
        end

        def jsonify &proc
          begin
            response = proc.call
            if response.is_a?(String)
              response = {status: 1, location: response}
            elsif response.is_a?(Array)

              params_updated = false
              response.each { |p| p.is_a?(Hash) && p.update(@query_string) && params_updated = true }
              response << @query_string unless params_updated

              response = {status: 1, location: http.route(*response)}
            end
          rescue => e
            @errors = e
            response = {status: 0, message: saint_view.render_partial('error')}
          end
          response.to_json
        end

        def path_related_params *params
          params_given = http.params.values_at(*params).compact
          return unless params_given.size == params.size
          params = params_given.map { |p| normalize_path(p, false, false) }
          params.size == 1 ? params.first : params
        end

        def encode_path path
          Base64.encode64(path).strip
        end

        def decode_path path
          Base64.decode64 path
        end

        def ls path
          Dir.glob('%s/*' % path, File::FNM_DOTMATCH).
              partition { |d| test(?d, d) }.flatten.
              select { |e| File.directory?(e) || File.file?(e) }.
              reject { |e| ['.', '..'].include? File.basename(e) }
        end

      end
    end
  end
end
