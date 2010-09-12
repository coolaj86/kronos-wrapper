#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'
require 'date'

TIMECARD_AT = '/html/body/form/table/tr[1]/td[1]/table[1]/tbody/tr'
NAME_AT = '/html/body/form/table/tr[1]/td[2]'
#PRESETS_AT = '/html/body/form/table/tr[1]/td[2]/table/tr[3]/td/select/optgroup/option'
#PERSON_ID_LIST = '/html/body/form/table/tr[1]/td[2]/table/tr[1]'
#PERSON_NAME_AND_ID = '/html/body/form/table/tr[1]/td[2]/table/tr[2]'

class Kronos
  # Kronos V 6.0
  # TODO parse version number of Kronos and assert that this works
  # TODO add asserts to prove that the page is the right page
  # TODO cleanup attr_accessors

  def initialize(server)
    kronprod = Mechanize::Mechanize.new
    @server = server
  end

  def self.parsedomain(url)
    #TODO given an arbitrary url to a kronos application, parse the application path
    # For example, either of the following should work
    # https://kronprod.byu.edu/wfc/applications/wtk/html/ess/logon.jsp
    # https://kronprod.byu.edu/wfc/applications/suitenav/navigation.do?ESS=true
    # server = kronprod.byu.edu
    false
  end

  def kronprod
    @kronprod = Mechanize::Mechanize.new unless @kronprod
    @kronprod
  end

  def authenticate(user, token)
    kronprod.get "https://#{@server}/wfc/applications/wpk/html/kronos-logonbody.jsp?ESS=true"
    @reply = kronprod.post "https://#{@server}/wfc/portal",
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

  def punch_in(job = nil)
    timestamp job unless punched_in
  end

  def punch_out
    timestamp unless punched_out
  end

  def transfer(job)
    # This allows transferring to the same job
    # is that good, bad? I dunno
    job && (timestamp job)
  end

  def punched_in
    #TODO look at today & yesterday's punches rather than all
    punches # determines @punched_in
    @punched_in
  end

  def punched_out
    !punched_in
  end

  def punches
    return @punches if @punches

    timecard.search(TIMECARD_AT).each do |row|
      @punches = [] unless @punches # chicken / egg problem with timecard
      punch = {
        :date => row.search('td[3]').inner_text.strip,
        :job => row.search('td[5]').inner_text.gsub!(/\//, ''),
        :in => row.search('td[4]').inner_text.strip,
        :out => row.search('td[6]').inner_text.strip,
        :shift => row.search('td[7]').inner_text.strip,
        :daily_total => row.search('td[8]').inner_text.strip,
      }
      # TODO combine overnight shifts ?
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

  def jobs
    #TODO parse jobs
    []
  end

  def presets
    #We could hard code this, or we can parse it
    #pp timecard.search(PRESETS_AT).inner_html
    options = {}
    timecard.forms.first.fields[8].options.each do |option|
      options[option.value] = option.text
    end
    options
  end
  
  private
    def timestamp(job = nil)
      @timecard = nil # old timecard is now invalid

      # TODO is there a reason for the trailing slashes?
      job = "////#{job}/" unless (job.nil? or job.index('////'))
      kronprod.get "https://#{@server}/wfc/applications/wtk/html/ess/timestamp.jsp"
      @reply = kronprod.post "https://#{@server}/wfc/applications/wtk/html/ess/timestamp-record.jsp",
        {
          :transfer => job,
        }
    end

    # TODO use presets and time ranges
    def timecard(preset = nil, begin_date = nil, end_date = nil)
      return @timecard if @timecard
      @punches = nil # punches are now invalid

      #TODO beware of special cases - what are they?
      #navigation = kronprod.get "https://#{@server}/wfc/applications/mss/managerlaunch.do?ESS=true"
      #timecard_html = navigation.links.find {|l| l.text =~ /My Timecard/}.click
      @timecard = kronprod.post "https://#{@server}/wfc/applications/mss/esstimecard.do?ESS=true",
        {
          :timeframeId => preset,
          :beginTimeframeDate => begin_date,
          :endTimeframeDate => end_date,
          #:beginningDate => '',
          #:endDate => '',
        }
      @timecard
    end
end
