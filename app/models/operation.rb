class Operation < Application
  attr_accessor :config, :pricings, :service,:operation,:usagetype,:resource,:starttime,:endtime,:usagevalue,:tier

  def initialize
    # load pricings
    self.config   = AppConfig
    self.pricings = Pricing
  end

  def <=>(o)
    operation_comp = self.operation <=> o.operation
    return operation_comp unless operation_comp == 0
    
    usagetype_comp = self.usagetype <=> o.usagetype
    return usagetype_comp unless usagetype_comp == 0
    
    return -1
  end

  def tier
    return nil unless @tier
    @tier.reverse.to_i
  end

  def usagevalue(type = 'data')
    return 0 unless @usagevalue

    case type
    when 'traffic'
      if self.usagetype.include?('Bytes') && !self.usagetype.include?('TimedStorage-ByteHrs')
        return @usagevalue.to_i                  
      end        
    when 'storage'                           
      # puts 'TimedStorage-ByteHrs' if self.usagetype
      if self.usagetype.include?('TimedStorage-ByteHrs')
        return @usagevalue.to_i / 744
      end
    when 'requests'
      if self.usagetype.include?('Requests')
        return @usagevalue.to_i
      end  
    else     
      return @usagevalue.to_i
    end
    0
  end
  
  def price
    case self.usagetype
    when 'EU-DataTransfer-Out-Bytes'
      self.pricings.eu['data_transfer']['out'] * (self.usagevalue(false)/1024**3)
    when 'DataTransfer-Out-Bytes'
      self.pricings.us['data_transfer']['out'] * (self.usagevalue(false)/1024**3)
    when 'EU-DataTransfer-In-Bytes'
      self.pricings.eu['data_transfer']['in'] * (self.usagevalue(false)/1024**3)
    when 'DataTransfer-In-Bytes'
      self.pricings.us['data_transfer']['in'] * (self.usagevalue(false)/1024**3)
    when 'EU-Requests-Tier1'
      self.pricings.eu['request']['tier1']['price'] * (self.usagevalue(false)/self.pricings.us['request']['tier1']['count'])
    when 'Requests-Tier1'
      self.pricings.us['request']['tier1']['price'] * (self.usagevalue(false)/self.pricings.us['request']['tier1']['count'])
    when 'EU-Requests-Tier2'
      self.pricings.eu['request']['tier2']['price'] * (self.usagevalue(false)/self.pricings.us['request']['tier2']['count'])
    when 'Requests-Tier2'
      self.pricings.us['request']['tier2']['price'] * (self.usagevalue(false)/self.pricings.us['request']['tier2']['count'])
    when 'EU-TimedStorage-ByteHrs'
      self.pricings.eu['storage'] * total_gb_month(self.usagevalue(false))
    when 'TimedStorage-ByteHrs'
      self.pricings.us['storage'] * total_gb_month(self.usagevalue(false))
    else
      0
    end
  end
  
  def total_gb_month(byte_hours)
    byte_hours / (1024**3) / 744
  end
  
  def starttime
    Time.parse(@starttime)
  end
  
  def endtime
    Time.parse(@endtime)
  end
  
  def to_xml
    xml = Builder::XmlMarkup.new(:indent => 4)
    xml.operation do
      xml.starttime self.starttime
      xml.endtime   self.endtime
      xml.operation self.operation
      xml.price     self.price
    end
    xml
  end
end