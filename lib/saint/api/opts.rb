module Saint
  
  # nodes including Saint::OptsApi get an extra method - #opts,
  # which is an interface to Opts Api(see {Saint::ClassApi#opts})
  #
  # @example
  #
  #    # backend - creating an GUI opts editor
  #    module Admin
  #      class Pages
  #        include Saint::Api
  #        saint.opts do
  #          opt :items_per_page, default: 10
  #        end
  #      end
  #    end
  #
  #    # frontend
  #    module Frontend
  #      class Pages
  #        # extending node to read opts set in backend
  #        include Saint::OptsApi
  #        # define opts manager
  #        opts Admin::Pages
  #        # read opts
  #        opts.items_per_page #=> 10
  #      end
  #    end
  module OptsApi
    def self.included node

      node.class_exec do

        define_singleton_method :opts do |*managers|
          @@opts ||= Class.new do
            managers.each do |manager|
              manager.class_exec { manager.opts_updater }
              manager.opts.opts.each_key do |opt|
                define_singleton_method opt do
                  val = nil
                  managers.each { |m| break if val = m.opts[opt] }
                  val
                end
              end
            end
          end
        end

        define_method :opts do
          self.class.opts
        end
      end
    end
  end
end
