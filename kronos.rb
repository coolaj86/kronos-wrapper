#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'

#TIMECARD_AT = '/html/body/form/table/tr[1]'
TIMECARD_AT = '/html/body/form/table/tr[1]/td[1]/table[1]/tbody/tr'
#NAME_AT = '/html/body/form/table/tr[1]/td[2]'
#RANGE_AT = '/html/body/form/table/tr[1]/td[2]'
#TOTAL_AT = '/html/body/form/table/tr[1]/td[1]'

class Kronos

  def initialize(server)
    @agent = WWW::Mechanize.new
    @server = server
    @reply = nil
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
    # TODO strip leading and trailing slashes
    # ... unless... is there actually a reason for them?
    job = "////#{job}/" #unless (job.nil? or job.index('////'))
    @agent.get "https://#{@server}/wfc/applications/wtk/html/ess/timestamp.jsp"
    @reply = @agent.post "https://#{@server}/wfc/applications/wtk/html/ess/timestamp-record.jsp",
      {
        :transfer => job,
      }
    # TODO return boolean
  end

  def punch_in(job = nil)
    # TODO check that I'm not already in, otherwise transfer or ignore
    timestamp job
  end

  def transfer(job)
    timestamp job
  end

  def punch_out
    # TODO check that I'm really in, otherwise ignore
    timestamp 
  end

  def jobs
    []
  end

  def timecard(preset = nil)
    #TODO beware of special cases
    @agent.get "https://#{@server}/wfc/applications/mss/managerlaunch.do?ESS=true"
    timecard = navigation.links.find {|l| l.text =~ /My Timecard/}.click
    @punches = []
    timecard.search(TIMECARD_AT).each do |row|
      punch = {
        :date => row.search('td[3]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :job => row.search('td[5]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :in => row.search('td[4]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :out => row.search('td[6]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :shift => row.search('td[7]').inner_text.gsub!(/[\302\240]*/, '').strip,
        :daily_total => row.search('td[8]').inner_text.gsub!(/[\302\240]*/, '').strip,
      }
      if (not punch[:in].empty?) && (punch[:out].empty?)
        @punched_in = true;
      end
      @punches << punch
    end
    pp @punches
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
end
