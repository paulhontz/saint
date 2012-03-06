module Saint
  class ClassApi

    # turn node into an File Manager
    def file_manager opts = {}, &proc
      @file_manager = FmExtender.new(@node, opts, &proc) if proc && configurable?
      @file_manager
    end

    alias :fm :file_manager
  end
end
