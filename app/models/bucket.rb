class Bucket < Application
  attr_accessor :name,:operations
  
  def initialize(name)
    @name = name
    self.operations = []
  end
  
  def <=>(o)
    price_comp =  o.price <=> self.price
    return price_comp unless price_comp == 0

    name_comp = self.name <=> o.name
    return name_comp unless name_comp == 0
    -1
  end
  
  def find_operation(needle)
    operations.detect{|o| o.operation == needle }
  end
  
  def time_range
    [
      self.starttime.strftime('%d %b %Y'),
      self.endtime.strftime('%d %b %Y')
    ].join(' -> ')
  end
  
  def starttime
    self.operations.map{|o| o.starttime }.sort.first
  end
  
  def endtime
    self.operations.map{|o| o.endtime }.sort.last
  end
  
  def price
    price = operations.inject(0) {|sum, o| sum + o.price }
    (price * 100).round.to_f / 100
  end      
                            
  # types available (traffic, requests, storage)
  def amount(type = 'traffic')
    operations.inject(0) {|sum, o| sum + o.usagevalue(type)}
  end              

  def to_xml(full = false)
    output = ''
    xml = Builder::XmlMarkup.new(:target => output, :indent => 4)
    xml.bucket do
      xml.name      self.name
      xml.starttime self.starttime
      xml.endtime   self.endtime
      xml.price     self.price.to_f
      if full
        xml.operations do
          operations.each do |o|
            xml.operation o.to_xml
          end
        end
      end
    end
    xml
  end

  def to_s
    buffer = []
    
    buffer << self.name
    
    buffer << '-'*50
    buffer << "SUMMARY"
    buffer << '-'*50
    buffer << "Date Range: #{self.time_range}"
    buffer << "Storage   : #{format(self.amount('storage'))}"
    buffer << "Traffic   : #{format(self.amount('traffic'))}"
    buffer << "Requests  : #{format(self.amount('requests'), 'numeric')}"
    buffer << "Total     : #{self.price.format_s(:usd)}"

    buffer.join("\n") + "\n"
  end
end