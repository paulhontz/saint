module Saint
  class FmExtender

    def initialize node

      fm_nodes = Hash.new
      node.saint.dashboard false
      node.saint.fm.roots.each_value do |root|

        fm_node = node.const_set root.name, Class.new

        fm_node.class_exec do

          include Saint::Api

          http.map node.http.route(root.name)
          saint.header root.label
          saint.dashboard false
          saint.menu do
            parent node
            label root.label
          end

        end
        fm_nodes[root] = fm_node
      end
      fm_nodes.each_pair do |root, fm_node|
        extend fm_node, root, fm_nodes.values
      end

      node.class_exec do

        include Saint::Utils

        define_method :index do
          @nodes = fm_nodes.values
          saint_view.render_layout saint_view.render_partial('fm/home')
        end
      end
    end

    def extend node, root, roots

      helper = Saint::FileManager::Helper.new
      node.class_exec do

        include Presto::Utils
        include Saint::Utils

        http.before :index, :create do |*path|
          @path = normalize_path(File.join(*path))
          @index_request_uri = http.route(:index, @path, http.get_params)
          @__meta_title__ = 'FileManager | %s | %s' % [saint.label, @path]
          @roots = roots
        end

        define_method :index do |*path|
          @label = root.label
          @active_dir, @active_file = nil
          scan
          @path.split('/').each { |dir| scan dir }
          saint_view.render_layout saint_view.render_partial('fm/index')
        end

        define_method :create do |*path|

          name = normalize_path(http.params['name'])
          type = http.post_params['type'] || 'file'
          node = File.join(root.path, @path, name)

          begin
            case type
              when 'file'
                FileUtils.touch node
                params = [@path, {file: File.join(@path, name)}]
              when 'folder'
                FileUtils.mkdir node
                params = [File.join(@path, name)]
              else
                return {status: 0, message: 'wrong type'}.to_json
            end
            response = {status: 1, message: 'Item Successfully Created', location: http.route(*params, '')}
          rescue => e
            @errors = e
            response = {status: 0, message: saint_view.render_partial('error')}
          end
          response.to_json
        end

        define_method :rename do

          return unless (path = http.params['path']) && (name = http.params['name'])
          path, name = [path, name].map { |v| normalize_path(v, true) }

          old_path = File.join(root.path, path)
          path = File.dirname(path)
          new_path = File.join(root.path, path, name)

          begin
            FileUtils.mv old_path, new_path
            status, message, location =
                1, 'Item Successfully Renamed',
                    File.file?(new_path) ?
                        http.route(path, file: File.join(path, name)) :
                        http.route(path, name)
          rescue => e
            @errors = e
            status, message = 0, saint_view.render_partial('error')
          end
          {status: status, message: message, location: location}.to_json
        end

        define_method :delete do
          begin
            path = normalize_path(http.params['path'])
            FileUtils.remove_entry_secure File.join(root.path, path)
            response = {status: 1, message: 'Item Successfully Deleted', location: http.route(File.dirname(path))}
          rescue => e
            @errors = e
            response = {status: 0, message: saint_view.render_partial('error')}
          end
          response.to_json
        end

        define_method :move do
          src, dst, current = http.params.values_at('src', 'dst', 'current').map { |v| normalize_path http.unescape(v.to_s) }
          begin
            FileUtils.mv(root.path + src, root.path + dst)
            status, message = 1, 'Item moved'
            current_path = root.path + current
            redirect_to = http.route(::File.file?(current_path) || ::File.directory?(current_path) ? current : dst)
          rescue => e
            @errors = ["Can not move %s" % File.basename(src), e.to_s]
            status, message = 0, saint_view.render_partial('error')
          end
          {status: status, message: message, redirect_to: redirect_to}.to_json
        end

        define_method :resize do

          return unless (path = http.params['path']) && (name = http.params['name'])
          path, name = [path, name].map { |v| normalize_path(v, true) }
          args = [
              http.params.values_at('width', 'height').map { |v| v.to_i },
              File.join(root.path, path),
              File.join(root.path, File.dirname(path), name),
          ].flatten

          resize_status = helper.resize(*args)
          if resize_status == true
            response = {status: 1, message: 'Image Resize Completed',
                        location: http.route(File.dirname(path), file: (File.join(File.dirname(path), name)))}
          else
            @errors = resize_status
            response = {status: 0, message: saint_view.render_partial('error')}
          end
          response.to_json
        end

        define_method :upload do

          dir, name = http.params.values_at('dir', 'name').map { |v| normalize_path v }
          wd = File.join(root.path, dir, '')

          @errors = []

          unless (File.file?(tempfile = http.params['file'][:tempfile]) rescue nil)
            @errors << "Was unable to upload file"
          end

          begin
            FileUtils.mv(tempfile, wd + name)
          rescue => e
            @errors << e.to_s
          end

          return 1 if @errors.size == 0
          saint_view.render_partial("error")
        end

        define_method :download do
          path = normalize_path http.params['file']
          file = File.basename(path)
          fs = Rack::File.new root.path + File.dirname(path)
          response = fs.call(http.env.merge('PATH_INFO' => file))
          response[1].update 'Content-Disposition' => "attachment; filename=#{file}"
          http.halt response
        end

        define_method :save do
          begin
            file = ::File.join(root.path, normalize_path(http.params['file']))
            ::File.open(file, 'w:utf-8') { |f| f << Saint::Utils.normalize_string(http.post_params['content']) }
            status, message = 1, 'File successfully saved'
          rescue => e
            @errors = ["File Not Saved", e.to_s]
            status, message = 0, saint_view.render_partial("error")
          end
          {status: status, message: message}.to_json
        end

        define_method :search do
          files = Array.new
          Find.find(root.path).select { |p| ::File.file?(p) }.each do |p|
            if ::File.basename(p) =~ /#{http.params['query']}/
              files << helper.file(p).merge(path: p.sub(root.path, ''))
            end
          end
          saint_view.render_partial 'fm/search', files: files
        end

        define_method :file do

          return unless file = http.params['file']
          file = normalize_path(file.to_s)
          return unless ::File.file?(full_path = ::File.join(root.path, file))
          hlp = Saint::FileManager::Helper.new
          file_details = hlp.file(full_path).update(
              path: file,
              name: ::File.basename(file),
              size: hlp.size(full_path, true),
              uniq: 'saint-fm-file-' << Digest::MD5.hexdigest(full_path),
              :file? => true
          )
          if file_details[:editable?]
            file_details[:content] = begin
              Saint::Utils.normalize_string ::File.open(full_path, 'r:binary').read
            rescue => e
              'Unable to read file: %s' % e.inspect
            end
          end
          if file_details[:viewable?]
            file_details[:url] = root.file_server[file]
            file_details[:geometry] = hlp.geometry(full_path)
          end
          saint_view.render_partial 'fm/partial/file', node: file_details
        end

        define_method :scan do |dir = nil|

          @dirs ||= Array.new
          @current_path ||= Array.new
          dir_path = File.join(*@current_path, dir||'')
          dir_full_path = File.join(root.path, dir_path, '/')
          return unless File.directory?(dir_full_path)
          @current_path << dir if dir
          @root_folder = dir.nil?

          nodes = {dirs: [], files: []}
          Dir[dir_full_path + "*"].each do |n|

            next unless (is_dir = File.directory?(n)) || File.file?(n)

            node = Hash.new
            node[:dir] = dir_path
            node[:name] = File.basename(n)
            node[:path] = File.join(dir_path, node[:name]).gsub(/^\/+|\/+$/, '')
            node[:uniq] = 'saint-fm-%s-' << Digest::MD5.hexdigest(node[:path])

            if is_dir

              node[:dir?] = true
              node[:icon] = helper.icon('folder')
              node[:uniq] = node[:uniq] % 'dir'

              if @path =~ /^#{node[:path]}\//
                node[:selected_dir?] = true
              end
              if @path == node[:path]
                @active_dir, node[:active_dir?] = node, true
              end

              nodes[:dirs] << node

            else

              node[:file?] = true
              node[:uniq] = node[:uniq] % 'file'
              node[:size] = helper.size(n, true)

              nodes[:files] << node.update(helper.file(n))
            end
          end
          @dirs << {name: dir, path: dir_path, nodes: nodes}
        end
        private :scan

      end
    end
  end
end
