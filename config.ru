require 'rack'
require 'sinatra'
require File.expand_path 'app', File.dirname(__FILE__)
run Sinatra::Application
