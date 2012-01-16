require 'ap'
require 'json'
require 'yaml'
require 'data_mapper'
require 'dm-types'
require 'dm-is-tree'
require 'mongo'

require File.expand_path('../../presto/lib/presto', File.dirname(__FILE__))
require File.expand_path('../../saint/lib/saint', File.dirname(__FILE__))
require File.expand_path('./config/config', File.dirname(__FILE__))

MONGODB_PORT = 20_000
MONGODB_PATH = "/tmp/presto/mongodb/"

cmd = 'rm -fr "%s"; mkdir -p "%s"; mongod --port %s --dbpath "%s" --logpath "%s/log" --fork ' % [
    MONGODB_PATH,
    MONGODB_PATH,
    MONGODB_PORT,
    MONGODB_PATH,
    MONGODB_PATH,
]

connect = lambda { MONGODB_CONN = Mongo::Connection.new("localhost", MONGODB_PORT) }

begin
  connect.call
rescue
  begin
    system cmd
    sleep 2
    connect.call
  rescue => e
    puts
    puts '*'*80
    puts
    puts "MongoDB Connection Failure. Make sure mongodb is running on port #{ MONGODB_PORT }"
    puts
    p e
    puts
    puts "to start it use:"
    puts
    puts cmd
    puts
    puts '*'*80
    puts
    exit 1
  end
end

%w[model assoc].each do |file|
  Dir[Pfg.model "**/#{file}.rb"].each { |f| require f }
end
DataMapper.finalize

%w[ctrl model admin test/*].each do |file|
  Dir[Pfg.ctrl "**/#{file}.rb"].each { |f| require f }
end

module Helper
  
end

APP = Presto::App.new
APP.helper Helper
APP.mount Ctrl do
  http.use Rack::CommonLogger
  http.use Rack::ShowExceptions
  view.root Pfg.view
  view.layouts_root Pfg.view
  view.layout :layout
end
