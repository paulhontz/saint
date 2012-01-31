require File.expand_path('../../../presto/lib/presto', __FILE__)
require File.expand_path('../../lib/saint', __FILE__)
require 'data_mapper'
require 'dm-is-tree'
require 'mongo'
require 'digest'
require 'json'
require 'yaml'
require 'ap'

Dir[File.expand_path('../extend/**/*.rb', __FILE__)].each { |f| require f }
require File.expand_path('../config/config', __FILE__)
require File.expand_path('../config/db', __FILE__)


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
