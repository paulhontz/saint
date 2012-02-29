require './load'
app = Presto::App.new do
  use Rack::ShowExceptions
  use Rack::CommonLogger
end
app.mount Ctrl, '/admin'
puts app.map.to_s
app.run server: :Thin, :Port => Cfg.port
