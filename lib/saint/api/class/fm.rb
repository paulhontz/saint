module Saint
  class ClassApi

    # turn node into an File Manager
    def file_manager opts = {}, &proc
      FmExtender.new(@node, opts, &proc) if proc && configurable?
    end

    alias :fm :file_manager
  end
end
