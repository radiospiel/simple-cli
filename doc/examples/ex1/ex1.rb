#!/usr/bin/env ruby
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem "simple-cli", '~> 0.3', path: "../../.."
end

module Ex1; end
module Ex1::CLI
  include Simple::CLI

  # Command without arguments
  #
  # Example:
  #
  #    ./ex1 hello:world
  #
  def hello_world
    puts "Hello from #{__FILE__}"
  end

  # Command with arguments
  #
  # This implements a command with arguments
  #
  # Examples:
  #
  #    ./ex1 hello --name=user "what's up"
  # 
  def hello(message, name: nil)
    if name
      puts "Hello #{name}: #{message}!"
    else
      puts "Hello, #{message}!"
    end
  end
end

$0 = "ex1"
Simple::CLI.run!(Ex1::CLI)
