# Upgrading from a previous version of RailsCollab

The only thing you should do is migrate the database schema to ensure RailsCollab's models 
continue to function. This can be achieved by running the following command:

    rake db:migrate

## Change in storage backend

File attachments now use ActiveStorage. If somehow you were previously using railscollab under Rails 3 and want it to work with the current Rails 7 version, you will need to migrate the file data manually.
