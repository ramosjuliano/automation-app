def start_appium_session
  logger 'STARTING APPIUM SESSION'
  execute_with_retry { start_driver }
  sleep 10
  logger 'APPIUM SESSION STARTED'
rescue StandardError => e
  raise logger "ERROR STARTING CONNECTION WITH APPIUM!\nERROR CLASS: #{e.class}\nERROR MESSAGE: #{e}\nDRIVER: #{$driver.pretty_inspect}\nBACKTRACE: #{e.backtrace.pretty_inspect}\n"
end

def close_appium_session
  logger 'ENDING APPIUM SESSION'
  driver_quit
  logger 'APPIUM SESSION FINISHED'
rescue StandardError => e
  raise logger "ERROR CLOSING CONNECTION WITH APPIUM!\nERROR CLASS: #{e.class}\nERROR MESSAGE: #{e}\nDRIVER: #{$driver.pretty_inspect}\nBACKTRACE: #{e.backtrace.pretty_inspect}\n"
end

def execute_with_retry(retries = 5)
  yield
rescue StandardError => e
  logger "RETRYING #{retries}...#{e.message}"
  sleep 2
  retries -= 1
  if retries.eql?(0) && e.message.eql?('A session is either terminated or not started')
    logger 'SESSION UNAVAILABLE, TRYING TO START ANOTHER ONE'
    start_driver
    sleep 2
    logger 'SESSION STARTED'
    retry
  end
  raise e unless retries.positive?

  retry
end

def print_execution_result(scenario)
  scenario_status = scenario&.passed? ? 'passed' : 'failed'
  log("STATUS: #{scenario_status}  |  DEVICE: #{DEVICE_ID}  |  APP UUID: #{UUID_APP_LABMOBILE || BUILD_NUMBER}")
  save_appium_server_log_on_file(scenario) if scenario_status.eql?('failed') && ENV.fetch('DEBUG_APPIUM_SERVER', nil)
  logger "RESULT: #{scenario_status.upcase}"
  execute_script("sauce:job-result=#{scenario_status}") if TEST_LOCATION.eql?('saucelabs')
rescue StandardError => e
  logger e
end

def print_execution_info(scenario)
  scenario_tags = ''
  scenario.tags.each { |tag| scenario_tags << "#{tag.name} " }
  log "#{Time.now.strftime('%d/%m %H:%M:%S')} | THREAD: #{THREAD_NUMBER} | DEVICE: #{DEVICE_NAME} #{DEVICE_ID}"
  logger "\n\n#{log_divider('*', 150)}\nSTARTING EXECUTION ON SCENARIO: #{scenario.name} | TAGS: #{scenario_tags}\n#{log_divider('*', 150)}\n"
rescue StandardError => e
  logger e
end

def logger(message, attach = nil)
  info = nil
  if defined?(THREAD_NUMBER) && defined?(DEVICE_NAME)
    info = "THREAD: #{THREAD_NUMBER} | DEVICE: #{DEVICE_NAME} #{DEVICE_ID} -> #{message}#{"\n#{attach}" if attach}"
    Kernel.puts "#{Time.now.strftime('%d/%m %H:%M:%S')} | #{info}" if LABMOBILE_DEBUG
    LOGGER_BY_DEVICE.info info
  else
    info = "#{message}#{"\n#{attach}" if attach}"
    puts "#{Time.now.strftime('%d/%m %H:%M:%S')} | #{info}"
    LOGGER_RAKE.info info
  end
  info
end

def log_divider(symbol, amount = 50)
  divider = ''
  amount.times { divider << symbol }
  divider
end

def save_appium_server_log_on_file(scenario)
  path = File.expand_path(File.join('..', '..', '..', 'logs', 'appium'), __dir__)
  FileUtils.mkdir_p(path)
  log_file_path = File.join(path, "#{scenario.name.parameterize.underscore}_#{Time.now.strftime('%d-%m-%Y__%H:%M:%S')}.log")
  logger "APPIUM LOG SAVED IN: #{log_file_path}"
  scenario_logs = scenario.get_log('server')
  File.open(log_file_path, 'w') do |file|
    scenario_logs.each { |log| file.puts(log.message) }
    file.close
  end
end

def wait_device_be_available_on_saucelabs(device_name)
  tries = 60
  tries.times do
    devices = JSON.parse(Excon.get("#{APP_CONFIG_DATA['caps']['saucelabs']['farmApiUrl']}/available", headers: { Authorization: APP_CONFIG_DATA['caps']['saucelabs']['farmApiToken'] }, expects: 200).body)
    break unless devices.select { |device| device.eql?(device_name) }.blank?

    logger "device #{device_name} isn't available, waiting and retrying..."
    sleep 10
  end
end

def create_temporary_directories
  create_directory_structure('features', { parent: 'reports' })
  create_directory_structure('logs')
  FileUtils.mkdir_p('tmp')
  FileUtils.mkdir_p('app')
end

def create_directory_structure(structure_type, **args)
  FileUtils.mkdir_p(args[:parent]) if args[:parent]
  base_path = args[:parent].nil? ? structure_type : File.join(args[:parent], structure_type)
  FileUtils.mkdir_p(base_path)
  location_and_platform_path = File.join(base_path, "#{ENV.fetch('TEST_LOCATION', nil)}_#{ENV.fetch('TEST_PLATFORM', nil)}")
  FileUtils.mkdir_p(location_and_platform_path)
  exec_type_path = File.join(location_and_platform_path, ENV.fetch('EXEC_TYPE', nil))
  FileUtils.mkdir_p(exec_type_path)
  return exec_type_path unless args[:scenario_status]

  create_directory_by_scnenario_status(exec_type_path, args[:scenario_status])
end

def create_directory_by_scnenario_status(exec_type_path, scenario_status)
  scenario_status_path = File.join(exec_type_path, scenario_status)
  FileUtils.mkdir_p(scenario_status_path)
  scenario_status_path
end

def create_app_file_path
  Dir[File.expand_path(File.join('..', '..', '..', 'app', "*.#{load_extension_by_platform}"), __dir__)]&.select { |artifact| artifact.split('/').last.eql?("#{BUILD_NUMBER}.#{load_extension_by_platform}") }&.first
end

# keep using environment variables instead of constants because this is also used in rake tasks
def load_extension_by_platform
  if ENV['TEST_PLATFORM'].eql?('android') then 'apk'
  elsif ENV['TEST_LOCATION'].eql?('local') then ENV['DEVICE_TYPE'].eql?('virtual') ? 'app' : 'ipa'
  elsif ENV['TEST_LOCATION'].eql?('labmobile') then 'ipa'
  else
    'zip'
  end
end
