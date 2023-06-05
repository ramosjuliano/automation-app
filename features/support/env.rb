['appium_lib', 'cucumber', 'documentos_br', 'faker', 'net/sftp', 'open3', 'parallel_tests', 'percentage', 'pry',
 'rexml/document', 'rspec', 'excon', 'appium_lib', 'rspec/expectations', 'rspec/core', 'rubygems', 'os', 'selenium-webdriver', 'savon', 'report_builder', 'touch_action', 'json', 'active_support/all'].each do |dependency|
  require dependency
end

EXEC_TYPE = ENV.fetch('EXEC_TYPE', nil)
PLATFORM = ENV.fetch('TEST_PLATFORM', nil)
THREAD_NUMBER = ENV.fetch('TEST_ENV_NUMBER', nil)
PARALLEL = ENV.fetch('TEST_PARALLEL', nil)
BUILD_NUMBER = ENV.fetch('TEST_BUILD_NUMBER', nil)
BITRISE_BUILD_ID = ENV.fetch('TEST_BITRISE_BUILD_ID', nil)
DEVICE_TYPE = ENV.fetch('DEVICE_TYPE', nil)
ALLOC_TYPE = ENV.fetch('ALLOC_TYPE', nil)
SESSION_TYPE = ENV.fetch('SESSION_TYPE', nil)
UUID_APP_LABMOBILE = ENV.fetch('UUID_APP_LABMOBILE', nil)
LABMOBILE_DEBUG = ENV.fetch('LABMOBILE_DEBUG', nil)
DEVICE = YAML.load_file(File.expand_path(File.join('..', '..', 'tmp', "devices_#{PLATFORM}.yaml"), __dir__))[THREAD_NUMBER.to_i - 1]
DEVICE_ID = DEVICE.split(':::').first
DEVICE_NAME = DEVICE.split(':::')[1]
TEST_LOCATION = DEVICE.split(':::').last
APP_CONFIG_DATA = YAML.load_file(File.expand_path(File.join('config', 'standard.yaml'), __dir__))
LOGGER = Logger.new(File.join('logs', "#{TEST_LOCATION}_#{PLATFORM}", EXEC_TYPE, "logger_#{Time.new.strftime('%d_%m_%Y')}.log"))
LOGGER_BY_DEVICE = Logger.new(File.join('logs', "logger_#{DEVICE_NAME.downcase.split.join('_')}_#{DEVICE_ID}.log"), File::CREAT)
APP_ENV_DATA = YAML.load_file("#{File.dirname(__FILE__)}/data_new/uat.yaml")
APP_STANDARD_DATA = YAML.load_file("#{File.dirname(__FILE__)}/data_new/standard.yaml")

Excon.defaults[:ssl_verify_peer] = false
Dir[File.join(File.dirname(__FILE__), 'commons', '*.rb')].sort.each { |file| require_relative file }
Dir[File.join(File.dirname(__FILE__), 'page_helper', '*.rb')].sort.each { |file| require_relative file }

logger("\n\n\n#{log_divider('#', 150)}\n#{log_divider(' ', 70)}NEW EXECUTION\n#{log_divider('#', 150)}\n\n")

#World(PageObjects)
Appium::Driver.new(load_appium_capabilities, true)
Appium.promote_appium_methods Object