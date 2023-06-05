desc 'Clean temporary directories'
task :clean_temporary_directories do
  `rm -rf logs tmp reports`
  puts 'temporary directories cleaned!'
end