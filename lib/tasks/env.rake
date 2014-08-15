namespace :rake_demo do

  desc "Show Unix Environment"
  task :show_env do
    sh 'env'
  end

  desc "Show Ruby Version"
  task :ruby_version do
    puts "Ruby Version is #{RUBY_VERSION}"
  end

  desc "Pass an argument to rake"
  task :do_it do
    puts "Doing it in with the rails environment set to #{ENV['RAILS_ENV']}"
  end

  desc "Pass an argument to rake"
  task :show_users => [:environment] do
    names = User.all.map(&:name)
    puts "User names are #{names.join(', ')}"
  end

end
