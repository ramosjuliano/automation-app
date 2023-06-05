desc 'Run tests dinamically based on the given parameters'
task :run_tests, %i[env_type type tags profiles alloc test_location platform device device_type release_id distribution_group session labmobile_debug] do |task, args|
  args.with_defaults(env_type: 'uat', type: 'all', alloc: 'dynamic', test_location: 'labmobile', device: '12', device_type: 'real', distribution_group: 'builds_develop', sut: 'app', session: 'separate', labmobile_debug: 'true')
  args.with_defaults(platform: platform_from_profiles(args.profiles))
  run_tests(task, args)
end

desc 'Run locally Android tests with specified tags!'
task :run_android, %i[tags release_id device device_type] do |task, args|
  args.with_defaults(env_type: 'uat', type: 'all', alloc: 'static', test_location: 'local', platform: 'android', device: 1, device_type: 'virtual', distribution_group: 'builds_develop', labmobile_debug: false)
  run_tests(task, args)
end

def platform_from_profiles(profiles)
  case profiles
  when /android/ then 'android'
  end
end

def run_tests(task, args)
  logger "\n\n\n#{log_divider('#', 150)}\n#{log_divider(' ', 60)}NEW EXECUTION #{Time.now.strftime('%d/%m/%Y %H:%M:%S')}\n#{log_divider('#', 150)}\n\n"
  init_env_variables(task, args)
  create_temporary_directories
  create_and_run_parallel_cucumber_command(args)
end

def init_env_variables(task, args)
  logger 'SETTING ENVIRONMENT VARIABLES', args
  ENV['JOB'] = task.to_s
  ENV['TEST_LOCATION'] = args[:test_location]
  ENV['TEST_PLATFORM'] = args[:platform]
  ENV['EXEC_TYPE'] = args[:type]
  ENV['DEVICE_TYPE'] = args[:device_type]
  ENV['ENVIRONMENT_TYPE'] = args[:env_type]
  ENV['TEST_BUILD_NUMBER'] = args[:release_id]
  ENV['ALLOC_TYPE'] = args[:alloc]
  ENV['SESSION_TYPE'] = args[:session]
  ENV['LABMOBILE_DEBUG'] = args[:labmobile_debug]
  ENV['JOB_TAGS'] = args[:tags]
rescue StandardError => e
  logger 'ERROR SETTING ENVIRONMENT VARIABLES', e
end

def create_and_run_parallel_cucumber_command(args)
  logger 'CREATING AND RUNNING PARALLEL CUCUMBER COMMAND'
  tags = create_tags_by_args(args)
  features_path_merged = features_path(**args, tags: tags)
  execute_command logger "bundle exec parallel_cucumber #{features_path_merged} -n #{number_of_devices(args)} --group-by scenarios --first-is-1 -o \"#{tags} #{create_profiles_by_args(args)}\" --fail-fast"
rescue StandardError => e
  raise logger 'ERROR EXECUTING PARALLEL CUCUMBER COMMAND', e
end

def features_path(**args)
  if args[:scenarios_paths]
    args[:scenarios_paths]
  elsif %w[bvt regression flaky failed].include?(args[:type])
    scenarios_path_by_quarantine(sut: args[:sut], type: args[:type], device: args[:platform], tags: args[:tags])
  else
    'features/'
  end
end

def load_features_path_from_file(args)
  paths = File.readlines(File.join(File.expand_path('..', __dir__), 'tmp', "scenarios_failed_by_farm_#{args[:platform]}.txt")).map(&:chomp).join(' ')
  raise logger 'SCENARIOS PATH NOT FOUND!' unless paths

  paths
end

def number_of_devices(args)
  logger 'SAVING THE LOADED DEVICES ON FILE'
  devices = get_devices_and_prepare_env(args)
  File.open(File.join(File.expand_path('..', __dir__), 'tmp', "devices_#{args[:platform]}.yaml"), 'w') do |file|
    file.write(devices.to_yaml)
    file.close
  end
  devices.size
rescue StandardError => e
  raise logger 'ERROR SAVING THE LOADED DEVICES ON FILE', e
end

def get_devices_and_prepare_env(args)
  # call dinamically load_local_devices, load_labmobile_devices, load_saucelabs_devices, load_all_devices or load_remote_devices
  devices = send("load_#{args[:test_location].downcase}_devices", args)
  ENV['TEST_PARALLEL'] = (devices.size > 1).to_s
  devices.empty? ? (raise logger 'NO AVAILABLE DEVICES!') : (logger "DEVICES THAT WILL BE STARTED: #{devices}")
  devices
end

def load_local_devices(args)
  logger 'LOADING LOCAL DEVICES'
  devices = []
  `adb start-server && open -a Appium`
  list_local_devices(devices, args)
  devices = select_devices_by_device_type(devices, args)
  initialize_local_devices(devices) if args[:device_type].eql?('virtual')
  devices
rescue StandardError => e
  raise logger 'ERROR LOADING LOCAL DEVICES', e
end

def select_devices_by_device_type(devices, args)
  return devices if args[:device].eql?('all')

  number_of_devices = args[:device]&.to_i if args[:device].to_s.size <= 2
  return devices[0..number_of_devices - 1] if number_of_devices

  select_device_by_name(devices, args)
end

def select_device_by_name(devices, args)
  if args[:test_location].eql?('labmobile')
    return select_group_of_devices_by_regex(devices, args) if args[:device].include?('==')
    return reject_group_of_devices_by_regex(devices, args) if args[:device].include?('##')
  end

  select_specific_device_by_name(devices, args)
end

def create_profiles_by_args(args)
  "#{'-p parallel' if ENV['TEST_PARALLEL']} #{normalize_profiles(args[:profiles])}".strip.squeeze(' ')
end

def create_tags_by_args(args)
  "-t 'not @wip #{" and #{'not' unless args[:type].eql?('bvt')} @bvt" if %w[bvt regression].include?(args[:type])} #{normalize_tags(args[:tags])}'".strip.squeeze(' ')
end

def normalize_tags(tags)
  "and #{tags.gsub('-t ', ' ')}" if tags
end

def normalize_profiles(profiles)
  "-p #{profiles.gsub('-p', ' ').split.join(' -p ')}" if profiles
end
