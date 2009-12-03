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
  #TODO add asserts to prove that the page is the right page

  def initialize(server)
    @agent = WWW::Mechanize.new
    @server = server
    @reply = nil
  end

  def parsedomain(url)
    #TODO given an arbitrary url to a kronos application, use that domain rather than... static method
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
    # TODO return boolean
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
    timestamp job unless not punched_out
    # TODO return boolean
  end

  def transfer(job)
    timestamp job
    # TODO return boolean
  end

  def punch_out
    timestamp unless not punched_in
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
    @agent.get "https://#{@server}/wfc/applications/mss/managerlaunch.do?ESS=true"
    timecard = navigation.links.find {|l| l.text =~ /My Timecard/}.click
    # TODO use presets and time ranges
    # TODO parse the year
    @punches = []
    timecard.search(TIMECARD_AT).each do |row|
      punch = {
        :date => row.search('td[3]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :job => row.search('td[5]').inner_text.gsub!(/[\302\240]*/, '').gsub!(/\//, '').strip,
        :in => row.search('td[4]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :out => row.search('td[6]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :shift => row.search('td[7]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :daily_total => row.search('td[8]').inner_text.gsub!(/[\302\240]*/, '').strip,
      }
      # TODO combine overnight shifts
      if not punch[:in].empty?
        punch[:in] = DateTime.strptime(punch[:date] + ' ' + punch[:in], '%a %m/%d %I:%M%p')
        if not punch[:out].empty?
          punch[:out] = DateTime.strptime(punch[:date] + ' ' + punch[:out], '%a %m/%d %I:%M%p') 
        end
        @punched_in = punch[:out].empty?
      end
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
