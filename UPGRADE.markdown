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
