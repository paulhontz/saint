require './init'
#APP.show_map
Rack::Handler::Thin.run APP.map, :Port => 8050
