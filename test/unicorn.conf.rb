require File.expand_path("init", File.dirname(__FILE__))

worker_processes 4
listen 8050
working_directory File.expand_path(File.dirname(__FILE__))
preload_app true
