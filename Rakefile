Dir.glob("tasks/*.rake").each { |r| import r }

task :default do
  #sh "rspec"
  sh "bundle exec rubocop"
end
