
To make use of built-in file manager, simply call #saint.fm with a block.

Block should define at least one root.

Multiple roots supported.

Each root should provide the absolute path to the folder to be managed.

    saint.fm do
        root '/some/path/'
        root '/some/another/path/'
    end

By default, Saint will use the folder name for root label.

To have a custom label for some root, use :label option.

    saint.fm do
        root '/path/to/templates'
    end
    # this will use Templates as label

    saint.fm do
        root '/path/to/templates', label: "Views"
    end
    # this will use Views as label

