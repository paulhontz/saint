require File.expand_path('../init', __FILE__)

%w[model assoc].each do |file|
  Dir[Pfg.model / "**/#{file}.rb"].each { |f| require f }
end

%w[ctrl admin test/*].each do |file|
  Dir[Pfg.ctrl / "**/#{file}.rb"].each { |f| require f }
end
