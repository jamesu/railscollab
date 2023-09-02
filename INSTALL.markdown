# Installing RailsCollab

Firstly, a word of warning. You will need a command prompt or terminal open in order to install RailsCollab. 

It would also be advisable to get yourself up to scratch with the finer details of Ruby on Rails deployment.

## Requirements

RailsCollab currently uses Rails 7, so be sure to use an appropriate version of ruby.

To install all required gems, simply run the following:

    bundle install

## Config files

The following configuration files need to be present:

* `config/database.yml` (the database configuration)
* `config/railscollab.yml` (the main configuration)

## Deployment

In order to facilitate deployment, a script located at `script/setup` 
has been provided, which will create an initial database.
It accepts the following environment variables:

	RAILSCOLLAB_INITIAL_USER
		The username of the administrative user
		(default='admin')
	RAILSCOLLAB_INITIAL_DISPLAYNAME
		The display name of the administrative user
		(default='Administrator')
	RAILSCOLLAB_INITIAL_PASSWORD
		The password of the administrative user
		(default='password')
	RAILSCOLLAB_INITIAL_EMAIL
		The email address of the administrative user
		(default='better.set.this@localhost')
	RAILSCOLLAB_INITIAL_COMPANY
		The initial name of the owner company
		(default='Company')
	RAILSCOLLAB_SITE_URL
		The url of your RailsCollab installation
		(default='http://localhost:3000')

The snippit:

	RAILSCOLLAB_INITIAL_USER="billg" \
	RAILSCOLLAB_INITIAL_DISPLAYNAME="Bill Gates" \
	RAILSCOLLAB_INITIAL_PASSWORD="microsoft" \
	RAILSCOLLAB_INITIAL_EMAIL="billg@microsoft.com" \
	RAILSCOLLAB_INITIAL_COMPANY="Microsoft" \
	RAILSCOLLAB_SITE_URL="projects.microsoft.com" \
	script/setup 

Then if you need a server for test purposes, run:

	rails server -p <port>

For more advanced deployment, refer to the Ruby on Rails documentation.
