# Installing RailsCollab

Firstly, a word of warning. You will need a command prompt or terminal open in order to upgrade RailsCollab. 

It would also be advisable to get yourself up to scratch with the finer details of Ruby on Rails deployment 
if you are planning on upgrading from ActiveCollab.

## From previous versions of RailsCollab

The first thing you should do is migrate the database schema to ensure RailsCollab's models 
continue to function. This can be achieved by running the following command:

    rake db:migrate

Next you should reload your configuration schema, in case any new configuration options have 
been added. This can be accomplished by running the following commands:

    rake db:railscollab:reload_config

If you are updating from alpha 2 and below, note that the preferred method for updating configuration 
options is now from the administration interface.

## From ActiveCollab (or ProjectPier 0.8)

RailsCollab uses a derivative of ActiveCollab's database model, which is similar 
but not identical to RailsCollab's.

In order to facilitate the migration from ActiveCollab to RailsCollab, 
a rake task called `db:railscollab:migrate_from_activecollab` has been provided,
which converts the tables in the current database (as specified in *config/database.yml*)
into a schema compatible with RailsCollab.

The rake task supports the following versions of ActiveCollab, which can
be explicitly specified by setting the ACTIVECOLLAB_VERSION environment 
variable:

* 0.7.1 - default

Note that any other version should be considered unsupported. However you should 
technically also be able to convert ProjectPier 0.8 databases over.
It should also be noted that ONLY MYSQL DATABASES ARE SUPPORTED by this task.
If for example you wanted to port over an ActiveCollab install but base 
everything in SQLite instead, you would probably be better using one of the 
as-of-yet non-existent web api's to copy everything over.

So to sum it up, you would do something like the following to upgrade:

1. Copy your ActiveCollab installation's MySQL database to a SEPERATE DATABASE called railscollab
2. Create a config/database.yml file based on config/database.yml.template, using either the development or production environments as your basis.
3. Run `rake db:railscollab:migrate_from_activecollab` from the root directory

And to make sure it works:
4. Run `script/server -e <insert development or production here>`
5. Go to http://localhost:3000 and login using your usual credentials
