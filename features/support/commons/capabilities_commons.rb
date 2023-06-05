def load_appium_capabilities
  opts = { caps: {}, appium_lib: {} }
  load_commons_capabilities(opts)
  # call dinamically load_ios_capabilities or load_android_capabilities
  send("load_#{PLATFORM.downcase}_capabilities", opts)
  # call dinamically load_local_capabilities, load_labmobile_capabilities or load_saucelabs_capabilities
  send("load_#{TEST_LOCATION}_capabilities", opts)
  logger 'CAPABILITIES LOADED', opts
  opts
end

def load_commons_capabilities(opts)
  opts[:caps][:platformName] = PLATFORM
  opts[:appium_lib][:server_url] = APP_CONFIG_DATA['caps'][TEST_LOCATION]['url']
  opts[:appium_lib][:clearSystemFiles] = true
  opts[:caps][:fastReset] = true
end

def load_ios_capabilities(opts)
  opts[:caps][:autoAcceptAlerts] = true
end

def load_android_capabilities(opts)
  opts[:caps][:autoGrantPermissions] = true
end

def load_local_capabilities(opts)
  opts[:caps][:deviceName] = DEVICE_ID
  opts[:caps][:udid] = DEVICE.split(':::')[1]
  opts[:caps][:app] = create_app_file_path
  opts[:caps][:systemPort] = THREAD_NUMBER.to_i + 8200 if PLATFORM.eql?('android')
  opts[:caps][:wdaLocalPort] = THREAD_NUMBER.to_i + 8100 if PLATFORM.eql?('ios')
  opts[:caps][:automationName] = APP_CONFIG_DATA['caps'][TEST_LOCATION]['automationName'][PLATFORM]
end

def change_capability_auto_grant_permissions(boolean)
  caps[:autoGrantPermissions] = boolean
end

def change_permissions_alerts_capabilities(boolean)
  caps[:autoGrantPermissions] = boolean
  caps[:autoAcceptAlerts] = boolean
end
