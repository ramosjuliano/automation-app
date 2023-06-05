%w[yaml os rake json open3 down pry excon active_support/all].each { |dependency| require dependency }

FileUtils.mkdir_p('logs')
PROJECT_NAME = 'test-app'.freeze
APP_CONFIG_DATA = YAML.load_file(File.expand_path(File.join('features', 'support', 'config', 'standard.yaml'), __dir__))
LOGGER_RAKE = Logger.new(File.join('logs', 'logger_rake.log'))

Dir[File.expand_path('features/support/commons/*.rb', __dir__)].map { |file| require_relative file }
Dir.glob('./rake/*.rake').map { |rake| load rake }
