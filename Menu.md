
Saint will automatically build an menu containing links to all pages.

Any class including `Saint::Api` will be automatically included in menu.

Label
---

Menu label is defaulted to node's header, set by `saint.header`

Use `label` to override this:

    saint.menu.label 'CMS Pages'
    # now menu label is "CMS Pages"


Nested menus
---

As easy as:

    class Cms
        saint.menu do
            void true
        end
    end

    class Pages
        saint.menu do
            parent Cms
        end
    end

    class News
        saint.menu do
            parent Cms
        end
    end


this will build a nested menu, having Cms label as root
and displaying Pages and News children on hover.

Cms wont link to any pages cause it is declared as void.
It only serve as parent container for Pages and News.

Position
---

Nodes will appear in menu in the order they was loaded by Ruby interpreter.

To have a custom order, use `position`.
Nodes with higher position will be placed first.

    class Pages
        saint.menu.position 100
    end

    class News
        saint.menu.position 200
    end


News will be placed first, though it was loaded last.

Prefix / Suffix
---

Menu label are placed inside &lt;a href=...&gt; tag.

If there are data to be placed before or after &lt;a href=...&gt; tag, use `prefix` and `suffix` accordingly.

Void menus
---

If some menu item should be displayed but not linked to any page, declare it void:

    class Cms
        saint.menu.void true
    end


Excluded nodes
---

To have an node excluded from menu, use `saint.menu.disabled`

    class Index
        include Saint::Api

        saint.menu.disabled
    end


Integration
---

To have menu displayed, simply call `Saint::Menu.new.render` in your layout:

    <body>
        <%= Saint::Menu.new.render %>
        ...
    </body>
