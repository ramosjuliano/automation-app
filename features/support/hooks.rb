COUNTDOWN = ENV.fetch('JOB_TAGS', nil).to_s.include?('@smoke_test') ? 600 : 900

Before do |scenario|
  start_appium_session
  logger 'EXECUTING AUTOMATION...'
  print_execution_info(scenario)
end

Around do |_scenario, block|
  retries = 3
  begin
    block.call
  rescue Selenium::WebDriver::Error::ServerError => e
    retries -= 1
    if retries.positive?
      logger "RETRYING... SERVER ERROR: #{e.message}"
      retry
    end
    logger e.message
    if e.message.include?('status code 500')
      write_failed_scenario_path_on_file(scenario)
      raise logger "ERROR ON LABMOBILE #{e.message}"
    end
  end
end

After do |scenario|
  print_execution_result(scenario)
  attach("data:image/png;base64,#{driver&.screenshot_as(:base64)}", 'image/png')
rescue StandardError => e
  logger e
ensure
  close_appium_session if SESSION_TYPE.eql?('separate')
end

BeforeAll do
    if ENV.fetch('TEST_ENV_NUMBER', nil) && ParallelTests.first_process?
    ReportBuilder.configure do |config|
      config.input_path = File.join('reports', 'features', "#{TEST_LOCATION}_#{PLATFORM}", EXEC_TYPE)
      config.additional_info = {
        'Release ID' => BUILD_NUMBER,
        'Bitrise build ID' => BITRISE_BUILD_ID,
        'Execution date' => Time.now.strftime('%d/%m/%Y %k:%M:%S'),
        'Environment type' => 'UAT',
        'Platform' => PLATFORM.upcase
      }
    end
  end
end

at_exit do
  logger "TEST_ENV_NUMBER: #{ENV.fetch('TEST_ENV_NUMBER', nil)}"
  logger "FIRST_PROCESS: #{ParallelTests.first_process?}"
  if ENV.fetch('TEST_ENV_NUMBER', nil) && ParallelTests.first_process?
    logger 'WAITING FINISH PROCESS'
    ParallelTests.wait_for_other_processes_to_finish
    logger 'FINISHED PENDING PROCESS'
    logger 'BUILDING REPORT WITH REPORT BUILDER'
    options = { report_path: File.join('reports', "features_report_#{PLATFORM}") }
    ReportBuilder.build_report ReportBuilder.options.merge(options)
    logger 'REPORT DONE'
  end
  logger "TEST_ENV_NUMBER: #{ENV.fetch('TEST_ENV_NUMBER', nil)} FINISHED"
end
