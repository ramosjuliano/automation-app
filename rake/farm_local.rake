def list_local_devices(devices, args)
  devices = send("list_#{ENV['TEST_PLATFORM'].downcase}_devices", devices, args)
  raise 'NO CONNECTED DEVICES FOUND!' if devices.empty?

  devices
end

def list_android_devices(devices, args)
  if args[:device_type].eql?('virtual')
    android_virtual_devices = `/Users/$USER/Library/Android/sdk/emulator/emulator -list-avds`
    raise 'NO VIRTUAL DEVICES FOUND, MAKE SURE YOU HAVE SOME VIRTUAL DEVICE CREATED!' if android_virtual_devices.empty?

    android_virtual_devices.split("\n").each_with_index { |device, index| devices << "#{device}:::emulator-#{%w[5554 5556 5558 5560 5562][index]}:::android:::local" }
  else
    android_real_devices = `/Users/$USER/Library/Android/sdk/platform-tools/adb devices -l`.split("\n").drop(1)
    raise 'NO REAL DEVICES FOUND, MAKE SURE THE DEVICE IS CONNECTED AND AVAILABLE AND TRY AGAIN!' if android_real_devices.empty?

    android_real_devices.each { |real_device| devices << "#{real_device.split[2]}:::#{real_device.split.first}:::android:::local" }
  end
  devices
end

def list_ios_devices(devices, args)
  if args[:device_type].eql?('virtual')
    list_ios_local_simulators(devices)
  else
    local_real_devices = `idevice_id -l`&.split("\n")
    raise 'NO REAL DEVICES FOUND, MAKE SURE THE DEVICE IS CONNECTED AND AVAILABLE AND TRY AGAIN!' if local_real_devices.nil? || local_real_devices.empty?

    local_real_devices.each_with_index { |device, index| devices << "iPhone #{index}:::#{device}:::ios:::local" }
  end
  devices
end

def list_iphones_by_state(state = nil)
  local_devices = []
  JSON.parse(`xcrun simctl list --json`)['devices'].each_value { |x| local_devices += x unless x.empty? }
  local_devices = local_devices.select { |local_device| local_device['name'].include?('iPhone') }
  return local_devices unless state

  local_devices.select { |local_device| local_device['state'].eql?(state) }
end

def list_android_by_state(state)
  list_of_local_devices = `adb devices`&.split("\n")
  return [] unless list_of_local_devices.size > 1

  list_of_local_devices[1..].select { |local_device| local_device.include?(state) }
end

def initialize_local_devices(devices)
  android_devices = devices.select { |device| device.split(':::')[2].eql?('android') }
  android_devices.each { |device| fork { `/Users/$USER/Library/Android/sdk/emulator/emulator -avd #{device.split(':::').first}` } }

  ios_devices = devices.select { |device| device.split(':::')[2].eql?('ios') }
  ios_devices.each { |device| fork { `xcrun simctl boot #{device.split(':::')[1]}` } }
  unused_devices = shutdown_unused_devices(ios_devices)
  `open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/` unless ios_devices.empty?

  total_devices = android_devices.size + ios_devices.size - unused_devices.size
  wait_until_devices_start_running(total_devices)
end

def shutdown_unused_devices(selected_devices)
  unused_devices = list_iphones_by_state('Booted').reject { |device_running| selected_devices.select { |selected_device| selected_device.split(':::')[1].eql?(device_running['udid']) } }
  unused_devices.each { |unused_device| fork { `xcrun simctl shutdown #{unused_device['udid']}` } }
  unused_devices
end

def wait_until_devices_start_running(total_devices)
  30.times do
    running_devices = 0
    running_devices += list_android_by_state('device').size if %w[android all].include?(ENV.fetch('TEST_PLATFORM', nil))
    break puts "#{total_devices} devices started and running..." if running_devices >= total_devices

    puts 'The devices are starting, waiting and retrying...'
    sleep 5
  end
end
