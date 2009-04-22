class Application
  def initialize(*options)
    
  end
  
  # this is the main method for running the program 
  def run
    report = File.join(AppConfig.paths['reports'], 'csv', Time.now.strftime("%y-%m") + '-previous_month.csv')
    unless File.exist?( report )
      Logger.info "Downloading usage report"
      Downloader.new.get
    end
    
    Logger.info "Analyse logfile..."
    report = Report.new(report)
    
    Logger.info "Saving txt"
    f = File.new( File.join(AppConfig.paths['reports'], 'txt', Time.now.strftime("%y-%m") + '-previous_month.txt'), 'w' )
    f.write(report.generate('txt'))
    f.close
    Logger.info "Saved txt"

    Logger.info "Saving xml"
    f = File.new( File.join(AppConfig.paths['reports'], 'xml', Time.now.strftime("%y-%m") + '-previous_month.xml'), 'w' )
    f.write(report.generate('xml'))
    f.close
    Logger.info "Saved xml"
  end

  # place shared application methods here
  def format(value, type = 'data')
    value = value.to_i
    case type
    when 'numeric'  
      case true
      when value < 1000
        value
      when value < 1000000   
        "#{value / 1000} Thousand"
      when value < 1000000000   
        "#{value / 1000000} Million"
      when value < 1000000000000
        "#{value / 1000000000} Billion"
      when value < 1000000000000000
        "#{value / 1000000000000} Trillion"
      when value < 1000000000000000000
        "#{value / 1000000000000000} Quadrillion"
      end
    when 'data'
      case true
      when value < 1024
        "#{value} bytes"
      when value < 1024**2
        "#{value / 1024} Kb"
      when value < 1024**3
        "#{value / 1024**2} MB"
      when value < 1024**4
        "#{value / 1024**3} GB"
      when value < 1024**5
        "#{value / 1024**4} TB"
      end
    end
  end
end
