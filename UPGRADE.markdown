# Upgrading from a previous version of RailsCollab

The only thing you should do is migrate the database schema to ensure RailsCollab's models 
continue to function. This can be achieved by running the following command:

    rake db:migrate

## Change in file storage location

If you are updating from the rails2 version of RailsCollab, the default location for Company logos, User avatars, and File data has changed. These are now located in "logo", "avatar" and "data".
If you have any existing files you should be able to copy them to the new location to make them work again.

Thats it!