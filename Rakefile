require "bundler/gem_tasks"

task :test do
  ret = true
  Dir["test/**/*.rb"].each do |f|
    ret = ret && sh("ruby #{f}")
  end
  exit(ret)
end
