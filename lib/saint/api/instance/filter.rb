module Saint
  class InstanceApi

    def filter_instances *types
      @node.saint.filter_instances @node_instance.http.params, *types
    end

    def filters?
      @node.saint.filters? @node_instance.http.params
    end

    def filter? column
      @node.saint.filter? column, @node_instance.http.params
    end

  end
end
