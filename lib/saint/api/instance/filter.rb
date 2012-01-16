module Saint
  class InstanceApi

    def filters *types
      @node.saint.filters @node_instance.http.params, *types
    end

    def filters?
      @node.saint.filters? @node_instance.http.params
    end

    def filter? column
      @node.saint.filter? column, @node_instance.http.params
    end

  end
end
