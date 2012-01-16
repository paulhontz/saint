module Ctrl
  class Fm

    saint.menu do
      label 'File Manager'
      position 1000
      void true
    end

    saint.fm do
      root File.expand_path('../../../fm-depot/public', __FILE__)
      root File.expand_path('../../../fm-depot/view', __FILE__), label: 'Templates'
    end
    
  end
end
