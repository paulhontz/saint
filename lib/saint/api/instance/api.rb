module Saint
  class InstanceApi

    attr_reader :orm

    def initialize node_instance

      @node, @node_instance = node_instance.class, node_instance

      @orm = Saint::ORM.new @node.saint.model, @node_instance
      @node.saint.before.each_pair { |a, p| @orm.before a, &p }
      @node.saint.after.each_pair { |a, p| @orm.after a, &p }

    end

    def meta_title
      @node_instance.http.flash[Saint::RV_META_TITLE]
    end

    def method_missing m, *args
      @node.saint.send(m, *args)
    end

  end
end
