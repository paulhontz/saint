require File.expand_path('../init', __FILE__)

%w[model assoc].each do |file|
  Dir[Pfg.model / "**/#{file}.rb"].each { |f| require f }
end

%w[ctrl admin test/*].each do |file|
  Dir[Pfg.ctrl / "**/#{file}.rb"].each { |f| require f }
end

APP = Presto::App.new

APP.use Rack::ShowExceptions
APP.use Rack::CommonLogger

APP.mount Ctrl do
  view.engine :Erubis
  view.root Pfg.view
  view.layouts_root Pfg.view
  view.layout :layout
end
