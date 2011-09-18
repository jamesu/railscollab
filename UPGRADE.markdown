# Upgrading from a previous version of RailsCollab

The first thing you should do is migrate the database schema to ensure RailsCollab's models 
continue to function. This can be achieved by running the following command:

    rake db:migrate

Next you should reload your configuration schema, in case any new configuration options have 
been added. This can be accomplished by running the following commands:

    rake db:railscollab:reload_config

Thats it!