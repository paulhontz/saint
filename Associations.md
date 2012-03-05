
Saint will manage all associations found on given model.

You can decide what associations to be managed and which to be ignored.

@example: manage only :author relation

    # DataMapper model
    class PageModel
        # basic setup
        belongs_to :author
        has n, :menus
        has n, :visits
    end

    # Saint setup
    class Page
        include Saint::Api
        saint.model PageModel do
            relations :author
        end
    end

@example: manage all relations but :visits

    class Page
        include Saint::Api
        saint.model PageModel do
            relations_ignored :visits
        end
    end

To ignore tree-related associations, use `tree_ignored` inside #model block:

    class Page
        include Saint::Api
        saint.model PageModel do
            tree_ignored true
        end
    end


Automatically defined associations can be fine-tuned later.

@example: manage :visits relations in readonly mode

    class Page
        include Saint::Api
        saint.model PageModel
        saint.has_n :visits, VisitsModel, readonly: true
    end



# Manually defining associations

Saint does support *"belongs to"*, *"has N"* and *"has N through"* associations.

Belongs to
---

To define a "belongs to" assoc, use `saint.belongs_to`,
passing as first argument the relation name and remote ORM model as second argument.

*Example:* game belongs to edition

    class Game
        saint.belongs_to :edition, Model::Edition
    end


Has N
---

To define a "has N" assoc, use `saint.has_n`,
passing as first argument the relation name and remote ORM model as second argument.

*Example:* game has N goals

    class Game
        saint.has_n :goals, Model::Goal
    end


Has N through
---

To define a "has N through" assoc, use `saint.has_n`,
passing as first argument the relation name, remote ORM model as second arg
and middle model as third arg.

*Example:* game has many scorers(players), through PlayersScorers model

    class Game
        saint.has_n :scorers, Model::Player, Model::PlayersScorers
    end


Tree
---

There are also tree association, when some item may belong to another item of same model.

*Example:* any page may have unlimited children pages

    class Pages
        saint.model Model::Page
        saint.is_tree
    end


Options
---

###column

When rendering association UI, Saint will display only first non-id column of remote model.

Use `column` inside block to instruct Saint about what columns to include and how to render them.

The syntax is same as when defining Saint columns by `saint.column`

*Example:* display name and email when rendering authors assoc UI

    class Pages
        saint.belongs_to :author, Model::Author do
            column :name
            column :email
        end
    end


*Example:* display page name plus an extra(non ORM) column

    class Authors
        saint.has_n :pages, Model::Page do
            column :name
            column :views do
                value { row.views }
            end
        end
    end


###remote_node

Saint needs only remote model for association to work.

However, there are 3 obvious benefits if associated model is managed by Saint as well:

*   assoc UI will get filters to search through remote items.
*   assoc UI will create links to remote items pages.
*   assoc UI will offer an "Create New" button to create new remote items in place.

To declare remote node, simply use `remote_node` inside block.

In example below, Pages is a Saint node and it is associated with authors model.
Saint will build an assoc UI without linking to authors pages,
cause authors are not managed by Saint,
i.e. there are no class including Saint::Api and using Model::Author as model.

    class Pages
        include Saint::Api

        saint.belongs_to :author, Model::Author
    end


In next example, both Pages and Authors are valid Saint nodes
and `remote_node` used accordingly, so assoc UI will have filters and links,
but not "Create New" button.

    class Authors
        include Saint::Api

        saint.model Model::Author
    end

    class Pages
        include Saint::Api

        saint.belongs_to :author, Model::Author do
            remote_node Authors
        end
    end


To have "Create New" buttons, simply set second argument of `remote_node` to true:
    
    saint.belongs_to :author, Model::Author do
        remote_node Authors, true
    end


###filter

By default, assoc UI will display all remote items.

Though it comes with a pager(and filters if remote node provided),
it is yet ineffective to loop through pages and use filters to find needed items.

More effective would be to display only needed items.

Saint associations comes with a handy #filter method,
that allow to build static and dynamic filters.

For static filters, simply pass a hash of columns with values:

*Example:* display only active authors:

    class Page
        saint.belongs_to :author, Model::Author do
            filter active: 1
        end
    end


For dynamic filters, pass a proc.
Proc will receive back the current local item, so you can create a hash using its data.

*Example:* display only teams of same region as current game:

    class Game
        saint.belongs_to :team, Model::Team do
            filter do |game|
                {region_id: game.edition.competition.region_id}
            end
        end
    end


To combine static and dynamic filters, pass both a hash and a proc.
If static and dynamic filters has same keys,
dynamic filters will override the static ones.

###order

Use `order` with a column and direction to modify the default extracting order.

By default, if remote node defined, items will be extracted by order defined at remote node,<br/>
otherwise, items will be extracted by remote primary key, in descending order.

*Example:* order games by date, newest first

    class Team
        saint.has_n :games, Model::Game do
            order :date, :desc
        end
    end


*Example:* order authors by name

    class Page
        saint.belongs_to :author, Model::Author do
            order :name
        end
    end


###items_per_page

Defaulted to 10

*Example:* display 100 games per page

    class Team
        saint.has_n :games, Model::Game do
            items_per_page 100
            # or
            ipp 100
        end
    end


###label

By default, saint will build the assoc label from provided name.

*Example:* here Saint will use "Pages" label

    class Author
        saint.has_n :pages, Model::Page
    end


*Example:* set custom label

    class Author
        saint.has_n :pages, Model::Page do
            label 'CMS Pages'
        end
    end


###readonly

*Example:* prohibit attaching / detaching remote items

    class Author
        saint.has_n :pages, Model::Page do
            readonly true
        end
    end


###callbacks

Allow to execute a callback before/after assoc updated

Association callbacks has an eventless aspect,
meant you can not define an callback for each event.

You can define a single callback and it will fire on any event,
being it create, update or delete.

*Example:* execute a callback BEFORE assoc created/updated/deleted

    saint.has_n :pages, Model::Page do
        before do
            # some logic
        end
    end


*Example:* execute a callback AFTER assoc created/updated/deleted

    saint.has_n :pages, Model::Page do
        after do
            # some logic
        end
    end


Keys
---

###local_key

The column on local model that should match the primary key of remote model.

*Example:*

    # scenario:
    #   relation: belongs_to
    #   local model: Model::City
    #   remote model: Model::Country

    class City
      saint.model Model::City
      saint.belongs_to :country, Model::Country
    end

    # this assoc expects Model::City to respond to #country_id,
    # as Model::City#country_id will be compared to Model::Country#id.
    # using #local_key to override this:

    class City
      saint.model Model::City
      saint.belongs_to :country, Model::Country do
        local_key :cntr_id
      end
    end
    # now Model::City#cntr_id will be compared to Model::Country#id


On has_n_through relations, local key is defaulted to name of local model suffixed by _id.

*Example:*

    # scenario:
    #   relation: has_n_through
    #   local model: Model::Page
    #   remote model: Model::Menu
    
    class Page
      saint.model Model::Page
      saint.has_n :menus, Model::Menu, Model::MenuPage
    end

    # this assoc expects Model::MenuPage to respond to #page_id,
    # as Model::Page#id will be compared to Model::MenuPage#page_id.
    # using #local_key to override this:

    class Page
      saint.model Model::Page
      saint.has_n :menus, Model::Menu, Model::MenuPage do
        local_key :pid
      end
    end
    # now Model::Page#id will be compared to Model::MenuPage#pid


###remote_key

The column on remote model that should match the primary key of local model.

*Example:*

    # scenario:
    #   relation: has_n
    #   local model: Model::Author
    #   remote model: Model::Page

    class Author
      saint.model Model::Author
      saint.has_n :pages, Model::Page
    end

    # this assoc expects Model::Page to respond to :author_id,
    # as Model::Author#id will be compared to Model::Page#author_id.
    # using #remote_key to override this:
    
    class Author
      saint.model Model::Author
      saint.has_n :pages, Model::Page do
        remote_key :auid
      end
    end
    # now Model::Author#id will be compared to Model::Page#auid


On has_n_through relations, remote key is defaulted to name of remote model suffixed by _id.

*Example:*

    # scenario:
    #   relation: has_n_through
    #   local model: Model::Page
    #   remote model: Model::Menu

    class Page
      saint.model Model::Page
      saint.has_n :menus, Model::Menu, Model::MenuPage
    end

    # this assoc expects Model::MenuPage to respond to #menu_id,
    # as Model::Menu#id will be compared to Model::MenuPage#menu_id.
    # using #local_key to override this:

    class Page
      saint.model Model::Page
      saint.has_n :menus, Model::Menu, Model::MenuPage do
        remote_key :mid
      end
    end
    # now Model::Menu#id will be compared to Model::MenuPage#mid

