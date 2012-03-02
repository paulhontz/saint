require './load'

#puts app.map.to_s
APP.run server: :Thin, :Port => Cfg.port
