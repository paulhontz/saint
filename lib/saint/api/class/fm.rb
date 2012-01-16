module Saint
  class ClassApi

    # turn node into an File Manager
    def fm &proc
      return @fm unless proc
      @fm = Saint::FileManager::Setup.new @node, &proc
      Saint::FmExtender.new @node
    end
  end
end
