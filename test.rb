#!/usr/bin/env ruby

require 'test/unit'
class TC_MyTest < Test::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_fail
    require 'rubygems'
    require 'mechanize'
    puts "\nTest everything except 'timestamp', 'punch_in', and 'transfer')"

    puts "Server: "
    puts "(kronprod.byu.edu by default)"
    server = gets.chomp 
    server = 'kronprod.byu.edu' if server.empty?

    puts "User: "
    user = gets.chomp

    puts "Passphrase: "
    puts "(your passphrase will not be shadowed, you will see it as you type)"
    token = gets.chomp

    puts "Transfer: "
    puts "(okay to leave blank)"
    job = gets.chomp

    require 'kronos.rb'

    kronos = Kronos.new server
    assert !kronos.authenticated
    assert kronos.authenticate user, token
    assert kronos.authenticated
    assert kronos.timecard
    if kronos.punched_in
      assert kronos.punched_in
      assert !kronos.punched_out
      assert !kronos.punch_in
    else
      assert !kronos.punched_in
      assert kronos.punched_out
      assert !kronos.punch_out
    end
  end
end

require 'test/unit/ui/console/testrunner'
Test::Unit::UI::Console::TestRunner.run(TC_MyTest)
