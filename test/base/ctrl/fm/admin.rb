module Ctrl
  class Fm

    #saint.menu.parent Ctrl::Author

    saint.menu do
      label 'File Manager'
      position -1000
      void true
    end

    saint.fm do
      root Pfg.tmp / :templates
      root Pfg.tmp / :public
    end

  end
end
