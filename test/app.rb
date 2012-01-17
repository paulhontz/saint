require './load'
APP.show_map
APP.run server: :Thin, :Port => Cfg.port
