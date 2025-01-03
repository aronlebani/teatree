#!/usr/bin/env ruby

# frozen_string_literal: true

require 'bcrypt'
require 'dotenv'
require 'fileutils'
require 'json'
require 'net/http'
require 'net/smtp'
require 'securerandom'
require 'sinatra'
require 'sinatra/flash'
require 'sqlite3'
require 'uri'

Dotenv.load

set :sessions, true
set :logging, true
set :session_secret, ENV['SESSION_SECRET'] || SecureRandom.hex(64)
set :views, File.join(__dir__, 'views')

DB = SQLite3::Database.new(ENV['DB_URL'])
DB.results_as_hash = true
DB.execute 'PRAGMA JOURNAL_MODE = wal'
DB.execute 'PRAGMA BUSY_TIMEOUT = 3000'

require './utils'
require './models'
require './routes'
