module Saint
  class ClassApi

    def tab id, opts = {}, &proc
      summary_tab(id, opts, &proc) unless opts[:summary] == false
      crud_tab(id, opts, &proc) unless opts[:crud] == false
    end

    # add a new summary tab.
    # @example add new tab
    #    saint.summary_tab :Statistics do
    #      view.render_partial :statistics
    #    end
    #
    # @example override master tab
    #    saint.summary_tab :master do
    #      # render some template
    #    end
    #
    # @param [Symbol] id
    #   unique id for created tab
    # @param [Hash] opts
    # @param [Proc] proc
    def summary_tab id, opts = {}, &proc
      tab = SaintTab.new(id, opts, &proc)
      summary_tabs[tab.id] = tab
    end

    # (see #summary_tab)
    def crud_tab id, opts = {}, &proc
      tab = SaintTab.new(id, opts, &proc)
      crud_tabs[tab.id] = tab
    end

    # return summary tabs added earlier
    def summary_tabs
      @summary_tabs ||= Hash.new
      @summary_tabs
    end

    # return crud tabs added earlier
    def crud_tabs
      @crud_tabs ||= Hash.new
      @crud_tabs
    end

  end

  class SaintTab

    attr_reader :id, :label, :proc

    def initialize id, opts = {}, &proc

      @id = id.to_s.gsub(/[^\w|\d|\-]/, '_').to_sym
      @label = (opts[:label] || Saint::Inflector.titleize(@id))
      @proc = proc || lambda { |*a| 'No block defined' }

    end

  end
end
