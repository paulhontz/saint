module Ctrl
  class Fm

    #saint.menu.parent Ctrl::Author

    saint.menu do
      label 'File Manager'
      position -1000
      void true
    end

    saint.fm do
      root File.expand_path '../test-unofficial/file-manager/templates', Pfg.root
      root File.expand_path '../test-unofficial/file-manager/public', Pfg.root
    end

  end
end
