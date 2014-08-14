## Action Mailer


#### Generate a mailer Ruby class and View

```
rails g mailer user_mailer signup_confirmation
```

We now have a app/mailers/user_mailer.rb and two views in the app/views/user_mailer directory.

#### Modify the app/mailers/user_mailer.rb class

Our emails will be from _ga@example.com_. We will send the email to the user's email address and make the user available to the views by creating a instance variable @user.  

```
class UserMailer < ActionMailer::Base
  # By default the email is from GA
  default from: "ga@example.com"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.signup_confirmation.subject
  #
  def signup_confirmation(user)
    # create an instance variable so that the view has access
    # to the user.
    @user = user

    # send email to the user
    mail to: user.email, subject: "Sign Up Confirmation"
  end
end
```

#### Modify the app/views/user_email/signup_confirmation.text.erb file.

```
<%= @user.name %>

Thank you for signing up.

```

#### Modify the UsersController#create action.

This will send the signup email.

 _Note: we are using a class method here but the Ruby class UserMailer only defines the instance method signup_confirmation. Rails maps the class method to the instance method._

```
def create
  ...
  if @user.save

        # Send sign up email
        UserMailer.signup_confirmation(@user).deliver
   ...
end
...
```

#### Modify the config/environments/development.rb file.

This will raise exceptions if sending the mail fails.

```
  # Do care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

```


#### Register a User. Which will send an email.


Go to the root URL, localhost:3000, and register a user. This will attempt to send an email.

__And it will FAIL.__


#### Configure the email setttings.

* Install and run the mailcatcher gem. See [mailcatcher site](http://mailcatcher.me/)
	```
	gem install mailcatcher
	mailcatcher
	```
* Add email configuration to the config/environments/development.rb file.

	```
	...
	# mailcatcher gem setup
  	config.action_mailer.delivery_method = :smtp
  	config.action_mailer.smtp_settings = { 
    :address => "localhost", :port => 1025 }
    ...
	```


* Register User at http://localhost:3000 with a valid email address.

* Check that email was sent, http://127.0.0.1:1080/



##### (Alternative to the above) Google Email Settings 
 Always getting an error here? Maybe because of two factor authentication?

* Add the dotenv gem to you Gemfile.  

	```
	gem 'dotenv-rails', :groups => [:development, :test]
	```

* bundle install
* Add your GMAIL credentials to the .env file.

	__MAKE SURE YOU DO NOT COMMIT THIS!!!!__   
	.gitignore should have .env in it.

* Add email configuration to the config/environments/development.rb file. 

```
... 
config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'example.com',
    user_name:            ENV["GMAIL_USERNAME"],
    password:             ENV["GMAIL_PASSWORD"],
    authentication:       'plain',
    enable_starttls_auto: true  }
  end
...
```

