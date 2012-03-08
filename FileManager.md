File Manager
---

To make use of built-in file manager, simply call `saint.fm` with a block.

Block should define at least one root.

Multiple roots supported.

Each root should provide the absolute path to the folder to be managed.

    saint.fm do
        root '/some/path/'
        root '/some/another/path/'
    end

### Options

#### Label

By default, Saint will use the folder name for root label.

Use :label option to have a custom label for some root:

    saint.fm do
        root '/path/to/templates'
    end
    # this will use "templates" as label

    saint.fm do
        root '/path/to/templates', label: 'Views'
    end
    # this will use "Views" as label

#### Max size for editable files

By default Saint will allow to edit only files less than 5MB.

Use :edit or :edit_max_size options to set custom size.

Size should be provided in bytes.

@example: set editable size to 10MB

    saint.fm do
        root '/some/folder', edit: 10 * 2**20
    end

#### Max file size that can be uploaded

By default Saint will allow to upload only files less than 10MB.

Use :upload or :upload_max_size options to set custom size.

Size should be provided in bytes.

@example: allow to upload files up to 100MB

    saint.fm do
        root '/some/folder', edit: 100 * 2**20
    end
