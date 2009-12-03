#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'date'

#TIMECARD_AT = '/html/body/form/table/tr[1]'
TIMECARD_AT = '/html/body/form/table/tr[1]/td[1]/table[1]/tbody/tr'
#NAME_AT = '/html/body/form/table/tr[1]/td[2]'
#RANGE_AT = '/html/body/form/table/tr[1]/td[2]'
#TOTAL_AT = '/html/body/form/table/tr[1]/td[1]'

class Kronos
  # Kronos V 6.0
  # TODO parse version number of Kronos and assert that this works
  #TODO add asserts to prove that the page is the right page
  #TODO cleanup attr_accessors

  def initialize(server)
    @agent = WWW::Mechanize.new
    @server = server
    @reply = nil
  end

  def self.parsedomain(url)
    #TODO given an arbitrary url to a kronos application, parse the application path
    # For example, either of the following should work
    # https://kronprod.byu.edu/wfc/applications/wtk/html/ess/logon.jsp
    # https://kronprod.byu.edu/wfc/applications/suitenav/navigation.do?ESS=true
    # server = kronprod.byu.edu
    server = ''
  end

  def authenticate(user, token)
    @agent.get "https://#{@server}/wfc/applications/wpk/html/kronos-logonbody.jsp?ESS=true"
    @reply = @agent.post "https://#{@server}/wfc/portal",
      {
        :username => user,
        :password => token,
        :ESS => 'true',
      }
    @authenticated = !@reply.links.find {|l| l.text =~ /Log Off/}.nil?
  end

  def authenticated
    @authenticated
  end

  def log_off
    #TODO log off
    false
  end

  def timestamp(job = nil)
    # TODO is there a reason for the trailing slashes?
    job = "////#{job}/" unless (job.nil? or job.index('////'))
    @agent.get "https://#{@server}/wfc/applications/wtk/html/ess/timestamp.jsp"
    @reply = @agent.post "https://#{@server}/wfc/applications/wtk/html/ess/timestamp-record.jsp",
      {
        :transfer => job,
      }
    # TODO return boolean
  end

  def punch_in(job = nil)
    timestamp job unless punched_in
    # TODO return boolean
  end

  def transfer(job)
    timestamp job
    # TODO return boolean
  end

  def punch_out
    timestamp unless punched_out
    # TODO return boolean
  end

  def jobs
    #TODO parse jobs
    []
  end

  def presets
    # TODO parse presets
    []
  end

  def timecard(preset = nil)
    #TODO beware of special cases
    navigation = @agent.get "https://#{@server}/wfc/applications/mss/managerlaunch.do?ESS=true"
    timecard_html = navigation.links.find {|l| l.text =~ /My Timecard/}.click
    # TODO use presets and time ranges
    # TODO parse the year
    @punches = []
    timecard_html.search(TIMECARD_AT).each do |row|
      punch = {
        :date => row.search('td[3]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :job => row.search('td[5]').inner_text.gsub!(/[\302\240]*/, '').gsub!(/\//, ''),
        :in => row.search('td[4]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :out => row.search('td[6]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :shift => row.search('td[7]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :daily_total => row.search('td[8]').inner_text.gsub!(/[\302\240]*/, '').strip,
      }
      # TODO combine overnight shifts
      if not punch[:in].empty?
        punch[:in] = DateTime.strptime(punch[:date] + ' ' + punch[:in], '%a %m/%d %I:%M%p')
        @punched_in = punch[:out].empty?
        if not punch[:out].empty?
          punch[:out] = DateTime.strptime(punch[:date] + ' ' + punch[:out], '%a %m/%d %I:%M%p') 
        end
      end
      punch[:date] = Date.strptime(punch[:date], '%a %m/%d')
      @punches << punch
    end

    @punches
  end

  def punches
    @punches
  end

  def punched_in
    #TODO look at today & yesterday's punches
    timecard unless @punches
    @punched_in
  end

  def punched_out
    not punched_in
  end
end
