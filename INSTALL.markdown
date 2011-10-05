# Installing RailsCollab

Firstly, a word of warning. You will need a command prompt or terminal open in order to install RailsCollab. 

It would also be advisable to get yourself up to scratch with the finer details of Ruby on Rails deployment, 
especially if you are not planning on deploying using Phusion Passenger.

## Requirements

RailsCollab requires Ruby 1.9.2 or later. There is no support for Ruby 1.8.x.

To install all required gems, simply run the following:

    bundle install

## Config files

The following configuration files need to be present:

* `config/database.yml` (the database configuration)
* `config/railscollab.yml` (the main configuration)

## Deployment

RailsCollab can most optimally be deployed via Phusion Passenger. Simply point a 
VirtualHost to "railscollab/public", and Passenger should do the rest, 
with the exception of setting up the database. You will need to do that yourself.

An example VirtualHost for Phusion Passenger deployment would be:

    <VirtualHost *:80>
	   ServerName megacorp.com
	   DocumentRoot /path/to/railscollab/public
    </VirtualHost>

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

So from scratch, you'd likely do something like to following to install:
1. Create a 'railscollab' database
2. Modify config/database.yml to suit your requirements
3. Run the snippit below
4. Insert the previously mentioned VirtualHost configuration into your Phusion Passenger installation.
5. Go to http://servername and login using your supplied credentials

The snippit:

	RAILSCOLLAB_INITIAL_USER="billg" \
	RAILSCOLLAB_INITIAL_DISPLAYNAME="Bill Gates" \
	RAILSCOLLAB_INITIAL_PASSWORD="microsoft" \
	RAILSCOLLAB_INITIAL_EMAIL="billg@microsoft.com" \
	RAILSCOLLAB_INITIAL_COMPANY="Microsoft" \
	RAILSCOLLAB_SITE_URL="projects.microsoft.com" \
	script/setup 


For more advanced deployment, refer to the Ruby on Rails documentation.
