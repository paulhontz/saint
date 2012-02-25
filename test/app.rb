require './load'
app = Presto::App.new do
  use Rack::ShowExceptions
  use Rack::CommonLogger
end
app.mount Ctrl
app.run server: :Thin, :Port => Cfg.port
