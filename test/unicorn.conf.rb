require File.expand_path('init', File.dirname(__FILE__))

worker_processes 4
listen 9000
working_directory File.expand_path(File.dirname(__FILE__))
