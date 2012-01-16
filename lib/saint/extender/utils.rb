module Saint
  module ExtenderUtils

    private

    def saint_view
      unless @saint_view
        @saint_view = Presto::View::Api.new
        @saint_view.engine Saint.view.engine
        @saint_view.root Saint.view.root
        @saint_view.scope self
      end
      @saint_view
    end

    def current_time
      Time.now.strftime("%b %d, %I:%M:%S %p")
    end

  end
end
