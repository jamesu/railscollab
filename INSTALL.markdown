# Installing RailsCollab

Firstly, a word of warning. You will need a command prompt or terminal open in order to install RailsCollab. 

It would also be advisable to get yourself up to scratch with the finer details of Ruby on Rails deployment, 
especially if you are not planning on deploying using Phusion Passenger.

## Requirements

Along with a working installation of the Ruby on Rails Framework, you will need the 
following to deploy & run RailsCollab:

* *iCalendar* - `sudo gem install icalendar`
* *RedCloth* - `sudo gem install redcloth`
* *ruby-openid* - `gem install ruby-openid`
* *ActionMailer* - `gem install ActionMailer`
* *Ferret* - `gem install ferret`

Plus the following which are *optional*:

* *Ruby/GD2* - http://gd2.rubyforge.org/ (for generating thumbnails and avatars)
* *AWS::S3* - `gem install aws-s3` (for Amazon S3 support)
* *Phusion Passenger* - http://www.modrails.com/ (for easy deployment)

## Deployment

RailsCollab can most optimally be deployed via Phusion Passenger. Simply point a 
VirtualHost to "railscollab/public", and Passenger should do the rest, 
with the exception of setting up the database. You will need to do that yourself.

An example VirtualHost for Phusion Passenger deployment would be:

    <VirtualHost *:80>
	   ServerName megacorp.com
	   DocumentRoot /path/to/railscollab/public
    </VirtualHost>

In order to facilitate deployment, a rake task called db:railscollab:install
has been provided, which will create an initial database.
The rake task accepts the following environment variables:

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

Note that as with any other database rake task, you will need to have the 
config/database.yml file present which contains the database connection
settings. An example file is present at config/database.yml.template,
which contains example settings.

So from scratch, you'd likely do something like to following to install:
1. Create a 'railscollab' database
2. Create a config/database.yml file based on config/database.yml.template, using either the development or production environments as your basis.
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
	rake db:railscollab:install


For more advanced deployment (e.g. using FastCGI or load balancing proxies), refer to the Ruby on Rails documentation.

## File Storage

RailsCollab allows the user to upload files, provided they have sufficient permissions. 
Files are stored according to the "File storage" option.

The current options available are "Database" and "Amazon S3" storage. 

"Database" will store your files directly in the database, and pull them out when required.
"Amazon S3" will use Amazon's S3 service to store your files. Please note that you will need to 
setup and Amazon account and enter the relevant details in the "Services" section in the configuration 
for this to work.

When using the "Database" storage option with MySQL, you might notice that files you 
upload may be limited to 64kb. To solve this issue, run `rake db:railscollab:fix_files`.
