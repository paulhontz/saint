module Saint
  class FmExtender

    def initialize node

      fm_nodes = Array.new
      node.saint.fm.roots.each_value do |root|

        fm_node = node.const_set root.name, Class.new

        fm_node.class_exec do

          include Saint::Api

          http.map node.http.route(root.name)
          saint.header root.label
          saint.menu do
            parent node
            label root.label
          end

        end
        extend fm_node, root
        fm_nodes << fm_node
      end

      node.class_exec do

        include Saint::ExtenderUtils

        define_method :index do
          @nodes = fm_nodes
          view.render_layout saint_view.render_partial('fm/home')
        end
      end
    end

    def extend node, root

      helper = Saint::FileManager::Helper.new
      node.class_exec do

        include Presto::Utils
        include Saint::ExtenderUtils

        http.before :index, :create, :save, :rename, :delete, :resize do |*path|
          @path = normalize_path(File.join(*path), true)
          @index_request_uri = http.route(:index, @path, http.get_params)
          http.flash[Saint::RV_META_TITLE] = 'FileManager | %s | %s' % [saint.h, @path]
        end

        define_method :index do |*path|
          @label = root.label
          @active_dir, @active_file = nil
          scan
          @path.split('/').each { |dir| scan dir }
          view.render_layout saint_view.render_partial('fm/index')
        end

        define_method :create do |*path|

          name = normalize_path(http.params['name'])
          node = File.join(root.path, @path, name)

          if File.directory?(node) || File.file?(node)
            http.flash[:alert] = "#{http.escape_html name} already exists"
            http.redirect @index_request_uri
          end

          begin
            if http.post_params['file']
              FileUtils.touch node
              params = [@path, {file: File.join(@path, name)}]
            else
              FileUtils.mkdir node
              params = [File.join(@path, name)]
            end
            http.redirect http.route(*params, '')
          rescue => e
            http.flash[:alert] = e.to_s
            http.redirect @index_request_uri
          end
        end

        define_method :rename do |*path|

          dir, name, name_was = http.params.values_at('dir', 'name', 'name_was').map do |v|
            normalize_path(v, true)
          end

          node_was = File.join root.path, dir, name_was
          node_new = File.join root.path, dir, name

          http.redirect(@index_request_uri) unless (is_dir = File.directory?(node_was)) || File.file?(node_was)

          if is_dir
            alert_var = :alert
            params = [File.join(dir, name)]
            proc = lambda { FileUtils.mv(node_was, node_new) }
          else
            alert_var = :file_alert
            params = [@path, {file: File.join(dir, name)}]
            proc = lambda { File.rename(node_was, node_new) }
          end

          if File.directory?(node_new) || File.file?(node_new)
            http.flash[alert_var] = "#{http.escape_html name} already exists"
            http.redirect @index_request_uri
          end

          begin
            proc.call
            http.flash[alert_var] = "Node successfully renamed at #{current_time}"
            http.redirect http.route(*params)
          rescue => e
            http.flash[alert_var] = e.to_s
            http.redirect @index_request_uri
          end
        end

        define_method :delete do |*path|

          dir, name = http.params.values_at('dir', 'name').map { |v| normalize_path v }
          node = File.join(root.path, dir, name)

          http.redirect(@index_request_uri) unless (is_dir = File.directory?(node)) || File.file?(node)

          params = is_dir ? [::File.dirname(@path)] : [@path]
          alert_var = is_dir ? :alert : :file_alert

          begin
            FileUtils.rm_rf node
            http.redirect http.route(*params)
          rescue => e
            http.flash[alert_var] = e
            http.redirect @index_request_uri
          end
        end

        define_method :move do
          src, dst = http.params.values_at('src', 'dst').map { |v| normalize_path v }
          begin
            FileUtils.mv(root.path + src, root.path + dst)
            json = {status: 1}
          rescue => e
            @errors = ["Can not move #{File.basename(src)}", e.to_s]
            json = {status: 0, error: saint_view.render_partial("error")}
          end
          json.to_json
        end

        define_method :resize do |*path|
          
          errors, alert_var = [], :file_alert
          final_path, final_file = '', ''
          file = normalize_path http.params['file']
          orig_file = File.join(root.path, file)

          if File.file?(orig_file)

            final_file = ::File.basename(file)
            final_path = ::File.dirname(file)

            if (final_name = normalize_path(http.params['name']).split('/').last.to_s).size > 0

              w, h = http.params.values_at('width', 'height').map { |v| v.to_i }

              resize_status = helper.resize(w, h, orig_file, File.join(root.path, final_path, final_name))
              if resize_status == true
                final_file = final_name
              else
                errors << resize_status
              end
            else
              errors << 'please specify file name'
            end
          else
            errors << 'target should be a file'
          end

          if errors.size > 0
            http.flash[alert_var] = errors.join('<br/>')
          end
          http.redirect http.route(final_path, file: File.join(final_path, final_file), _: rand)
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

        define_method :save do |*path|
          begin
            file = root.path + normalize_path(http.params['file'], true)
            ::File.open(file, 'w:UTF-8') { |f| f << Saint::Utils.normalize_string(http.post_params['content']) }
            http.flash[:file_alert] = "File successfully saved at #{current_time}"
          rescue => e
            @errors = ["File Not Saved", e.to_s]
            http.flash[:file_alert] = saint_view.render_partial("error")
          end
          http.redirect @index_request_uri
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
            node[:uniq] = 'saint-fm-%s-' + Digest::MD5.hexdigest(node[:path])

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
              node.update helper.file(n)

              node[:size] = helper.size(n, true)

              if node[:path] == http.params['file'].to_s.gsub(/^\/+|\/+$/, '')

                @active_file, node[:active_file?] = node, true
                file_path = root.path + node[:path]

                if node[:editable?]
                  node[:content] = begin
                    Saint::Utils.normalize_string ::File.open(file_path, 'r:UTF-8').read
                  rescue => e
                    "Unable to read file: #{e}"
                  end
                end
                if node[:viewable?]
                  node[:url] = root.file_server[node[:path]]
                  node[:geometry] = helper.geometry(n)
                end
              end
              nodes[:files] << node
            end
          end
          @dirs << {name: dir, path: dir_path, nodes: nodes}
        end
        private :scan

      end
    end
  end
end
