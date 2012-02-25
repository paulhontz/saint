module Saint
  module Api

    def self.included node

      node.respond_to?(:http) || node.send(:include, ::Presto::Api)

      node.node.on_init do
        node.class_exec do
          def saint
            @__saint_api_instance__
          end
        end
        @__saint_api_instance__ = Saint::InstanceApi.new(self)
      end

      class << node
        def saint
          @__saint_api_class__ ||= Saint::ClassApi.new(self)
        end
      end

      Saint.nodes << node
    end
  end
end
