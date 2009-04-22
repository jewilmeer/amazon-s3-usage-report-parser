unless defined?(APP_ROOT)
  puts ENV.inspect
  APP_ROOT = File.expand_path(File.join( File.dirname(__FILE__), '..'))

  # handle environments
  APP_ENV = ARGV[0] || 'development'

  # 3th party spullen
  %w[rubygems extensions/all csv yaml ostruct time mechanize builder].each {|r| require r}
  # own classes
  Dir.glob(APP_ROOT + '/app/**/*.rb').each {|f| require f}
  
  # load configuration object
  ::AppConfig = OpenStruct.new(YAML.load_file("#{APP_ROOT}/config/config.yml"))
  ::Pricing   = OpenStruct.new(YAML.load_file("#{APP_ROOT}/config/pricing.yml")['pricing'])

  # extend some paths
  AppConfig.paths.each do |key, path|
    AppConfig.paths[key]= "#{APP_ROOT}/#{path}"
  end
  
  # log configuration
  require 'logging'
  Logging.init :debug, :info, :warn, :error, :fatal

  layout = Logging::Layouts::Pattern.new :pattern => "[%d] [%-5l] %m\n"

  # Default logfile, history kept in files of 1MB each
  default_appender  = Logging::Appenders::RollingFile.new 'default', \
    :filename => "#{APP_ROOT}/log/#{APP_ENV}.log", :size => 1024 * 1024, :keep => 10, :safe => false, :layout => layout

  ::Logger = Logging::Logger['server'] 
  Logger.add_appenders default_appender

  if APP_ENV == 'development'
    # STDOUT logger to see output on screen
    debug_appender    = Logging::Appenders::Stdout.new 'default', :layout => layout
    Logger.add_appenders debug_appender
  end

  Logger.level = APP_ENV == 'development' ? :debug : :info
end