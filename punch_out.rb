#!/usr/bin/env ruby

  server = 'kronprod.byu.edu'
  user = 'CHANGE_ME_USERNAME'
  token = 'CHANGE_ME_PASSWORD'

  require 'kronos.rb'
  puts 'Clocking Out'
  kronos = Kronos.new server
  kronos.authenticate user, token
  kronos.punch_out
  sleep 10
  pp kronos.punched_out
