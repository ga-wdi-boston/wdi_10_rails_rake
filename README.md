## Rake

Is a build tool, like Make, written in Ruby and using Ruby as a build language. 

* Let you define tasks
* Tasks can depend on other tasks
* Tasks are only run if needed.
* Tasks are only run once.

### Task
* Create a file.
* Populate a DB from a CSV, XML file.
* Dump DB to a file.
* Automation.
	Something you do a lot.
* See Rails for some great examples of Tasks.


##### Basics

First we will use Rake in an empty directory. _Just to see how we can use rake outside of Rails_.

* Install rake.  _Can't imagine you don't already have it._
	``gem install rake`` 
* Create a directory 'RakeStuff' and cd to that directory.
* Create a file 'Rakefile'. _Add the below code to that Rakefile._
* Create a hello task using the __task__ keyword/method.

	```
	task :default do
      puts "say something"
	end
	```
* Run Task.  
	``$ rake hello``
* Show all tasks.  
	``$ rake -T`` or ``$ rake -D`` or ``$ rake -P``

* Show where a rake tasks is implemented.  
	``rake -W``
	
* Create another hello task with another action and run it.  

	```
  	task :hello do
      puts "Hello from my first rake task"
   	end
	```

	When running ``$rake hello`` this just gives the hello task another action.
	
* Document the task.  
	Use the __desc__ keyword/method.
	Add 'desc "Some descriptive text" directly above the task.
	
	```
	desc "Just say Hello"
	task :hello do
	  puts "Hello from my first rake task"
	end
	```
	
	``$rake hello``
	``$rake -D hello``


##### Namespaces

To avoid name collisions with other rake tasks, probably defined in gems or libraries. Use the __namespace__ keywork/method.

Yes, namespaces can be nested.

```
namespace :rack_demo do
  namespace :simple do
    task :default do
      puts "say something"
    end
...
  end
end
```

##### Dependencies

Rake is very good at running tasks that __depend__ on other tasks. 
* Create a set of tasks to bake a cake, in rakelib/cake.rake.

```
namespace :cake do

  desc "Bake a Cake"
  task :bake => [:mix_up, :go_to_store] do
    puts "Cake is baked"
  end

  task :mix_up => [:add_flower, :add_eggs] do
    puts "Mix up ingredients"
  end

  task :add_flower => :get_flower do
    puts "Adding flower"
  end

  task :add_eggs => :go_to_store do
    puts "Adding Eggs"
  end

  task :get_flower => [:go_to_store] do
  puts "Get Flower"
  end

  task :go_to_store do
    puts "Go to Store"
  end
end
	
```

Run this bake task.   
``$ rake cake:bake``  

Notice how the output.   

```
Go to Store
Get Flower
Adding flower
Adding Eggs
Mix up ingredients
Cake is baked

```

This will create a dependency tree where the bake task depends on the mix_up task which depends on the add_flower and add_eggs tasks. 

The add_flower task depends on the get_flower task which depends on the got_to_store task. 

The add_eggs tasks just depends on the go_to_store task.


_Notice how we do NOT invoke dependencies twice! Even when they are explicity added as a dependency._ 

Rake knows not to include a dependency that has already been met.


##### Running Unix commands

We can invoke Unix commands from within a rake task.  

Add this to rakelib/env.rb. 

```
namespace :rake_demo do

  task :show_env do
    sh 'env'
  end
end
```

``rake rake_demo:show_env``  


##### Passing arguments to Rake and environment.

* Show Unix Environment Variables.  
	``$ env``
	
	Notice the RUBY_VERSION. 
* Access a Environment Variable in rake.

``$ export RAILS_ENV='development'``  
``$ rake rake_demo:do_it``

```
... 
 desc "Pass an argument to rake"
  task :do_it do
    puts "Doing it in with the rails environment set to #{ENV['RAILS_ENV']}"
  end
...
```

Unset the environment variable and pass it directly as an argument.

``$ unset RAILS_ENV``  
``$ rake rake_demo:do_it RAILS_ENV='foo' ``


### Rake in Rails.

Move all these *.rake files to a Rails app. _This app_.

Rails will look for all rake tasks in it's lib/tasks directory.

Add this task to the env.rake file. 

```
 desc "Pass an argument to rake"
  task :show_users => [:environment] do
    names = User.all.map(&:name)
    puts "User names are #{names.join(', ')}"
  end

```