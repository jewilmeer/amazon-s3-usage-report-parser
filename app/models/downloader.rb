class Downloader < Application
  attr_accessor :agent
  
  def initialize
    self.agent  = WWW::Mechanize.new
  end

  def login(form)
    Logger.debug "Logging in with #{AppConfig.user['login']}"
    form.email    = AppConfig.user['login']
    form.password = AppConfig.user['password']
    form.submit
  end
  
  # return original page or login form
  def needs_login?(page)
    login_form = page.forms.detect {|f| f.action.include?('sign-in') }
    login_form ? login_form : page
  end
  
  def get
    Logger.debug "Getting #{AppConfig.links['usage_report']}"
    agent.get(AppConfig.links['usage_report']) do |page|
      # login if needed
      login_form = needs_login?(page)
      page       = login(login_form) if login_form
    end
    
    # get usage report of previouw month
    Logger.debug "Getting report from: #{AppConfig.links['download_report']}"
    filename = Time.now.strftime("%y-%m") + '-previous_month.csv'
    agent.get(AppConfig.links['download_report']) \
    .save(AppConfig.paths['reports'] + "/csv/" + filename)
    
    Logger.info "Saved #{filename}"
    
    filename
  end
end