# All just Ruby code here.
namespace :rack_demo do
  namespace :simple do
    task :default do
      puts "say something"
    end

    # run "rake hello"
    desc "Just say Hello"
    task :hello do
      puts "Hello from my first rake task"
    end

    # Give the rake 'hello' task another action.
    # Does not overwrite the previous
    task :hello do
      puts "Say Hello again"
    end
  end
end
