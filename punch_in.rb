#!/usr/bin/env ruby

  server = 'kronprod.byu.edu'
  user = 'CHANGE_ME_USERNAME'
  token = 'CHANGE_ME_PASSWORD'

  require 'kronos.rb'
  puts 'Clocking In'
  kronos = Kronos.new server
  kronos.authenticate user, token or return
  kronos.punch_in 'job 2'
  sleep 10
  pp kronos.punched_in
