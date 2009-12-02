#!/usr/bin/env ruby
require 'rubygems'
require 'mechanize'

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
    navigation = @agent.get "https://#{@server}/wfc/applications/mss/managerlaunch.do?ESS=true" #iframe only
    timecard = navigation.links.find {|l| l.text =~ /My Timecard/}.click
    #reply = @agent.get "https://#{server}/wfc/applications/mss/navigation.do?ESS=true" #iframe only
    []
  end

  def raw_output
    @reply
  end
end
