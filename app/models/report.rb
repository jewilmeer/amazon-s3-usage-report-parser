class Report < Application
  attr_accessor :file_location, :report_array, :buckets
  def initialize(file_location)
    self.buckets = []
    self.file_location = file_location

    case File.extname(file_location)
    when '.csv'
      report_array = csv_to_array(file_location)
    else
      Logger.error "can't handle file"
    end

    Logger.info "Creating report"
    create_report(report_array)
  end
  
  def csv_to_array(file_location)
    csv = CSV::parse(File.open(file_location, 'r') {|f| f.read })
    # first row should be fieldnames
    fields = csv.shift.map { |key| key.delete(" ").downcase }
    csv.collect { |record| Hash[*fields.zip(record).flatten ] }
  end

  def create_report(array)
    array.each_with_index do |row, i|    
      next unless row['resource'] 
      # make or find the bucket
      self.buckets << bucket = Bucket.new(row['resource']) unless self.buckets.map{|n| n.name}.include?(row['resource'])
      bucket ||= find_bucket(row['resource'])
      
      operation = Operation.new                               
      row.each {|key, value| operation.send("#{key}=", value)} 
      bucket.operations = bucket.operations | [operation]
    end
    return true
  end

  def find_bucket(bucket_name)
    self.buckets.each do |b|
      return b if b.name == bucket_name
    end
  end

  def show_operation(op)
    puts "#{op.operation}: #{op.usagetype}(#{op.usagevalue})"
  end
  
  def operation(op, format = 'txt')
    case format
    when 'xml'
      return 'leeg'
    when 'txt'
      "#{op.operation}: #{op.usagetype}(#{op.usagevalue})"
    else
      "#{op.operation}: #{op.usagetype}(#{op.usagevalue})"
    end
  end
  
  def generate(format = 'txt')

    Logger.info "Generate #{format} output"

    output = ''
    case format
    when 'xml'
      xml = Builder::XmlMarkup.new(:target => output, :indent => 4)
      xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
      xml.report( :id => File.basename(file_location, '.csv') ) do
        xml.buckets do
          self.buckets.sort.each do |b|
            xml.bucket do
              xml.name      b.name
              xml.traffic   self.format(b.amount('traffic'))
              xml.requests  b.amount('requests').format_s(:eu)
              xml.price({:format => 'usd'}, b.price.format_s(:usd))
            end
          end
          xml.totals do
            xml.data_traffic  format(self.amount('traffic'))
            xml.data_storage  format(self.amount('storage'))
            xml.requests      format(self.amount('requests'), 'numeric')
            xml.costs         self.price.format_s(:usd)
          end
        end
      end
    when 'txt'
      self.buckets.sort.each do |bucket|
        output << "="*50 + "\n"
        output << bucket.to_s
        output << "="*50 + "\n\n"
      end
      
      output << "="*50 + "\n"
      output << "TOTALS" + "\n"
      output << '-'*50 + "\n"
      output << "Data traffic: #{format(self.amount('traffic'))}" + "\n"
      output << "Data storage: #{format(self.amount('storage'))}" + "\n"
      output << "Requests    : #{format(self.amount('requests'), 'numeric')}" + "\n"
      output << "Costs       : #{self.price.format_s(:usd)}" + "\n"
      output << '='*50 + "\n"
    end

    return output

    #   puts '='*50
    #   puts bucket.name
    #   
    #   puts '-'*50
    #   puts "SUMMARY"
    #   puts '-'*50
    #   puts "Date Range: #{bucket.time_range}"
    #   puts "Storage   : #{format(bucket.amount('storage'))}"
    #   puts "Traffic   : #{format(bucket.amount('traffic'))}"
    #   puts "Requests  : #{bucket.amount('requests').format_s(:eu)}"
    #   puts "Total     : "+ bucket.price.format_s(:usd)
    #   puts '='*50      
    #   puts ''
    # puts '='*50      
    # puts "TOTALS"
    # puts '-'*50
    # puts "Data traffic: #{format(self.amount('traffic'))}"
    # puts "Data storage: #{format(self.amount('storage'))}"
    # puts "Requests    : #{format(self.amount('requests'), 'numeric')}"
    # puts "Costs       : #{self.price.format_s(:usd)}"
    # puts '='*50      
    # puts ''
  end
  
  def price
    self.buckets.inject(0) { |sum, b| sum + b.price }
  end  
  
  def amount(type = 'traffic')
    self.buckets.inject(0) { |sum, b| sum + b.amount(type) }
  end  
  
  def to_s
    
  end
  
  def to_xml
    
  end
end