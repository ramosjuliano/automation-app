def execute_command(command, exception: true)
  `bundle` unless File.exist?('Gemfile.lock')
  puts command
  system(command, exception: exception)
rescue StandardError => error
  raise 'Erro de execução no Bundler' if error.to_s.include? 'bundler: failed to load command: parallel_cucumber'
end
