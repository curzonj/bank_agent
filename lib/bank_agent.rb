require 'mechanize'
require 'fastercsv'
# ofx_client has lots of dependencies
# that it requires directly

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'loggable'
require 'retryable'
require 'ledgers_client'
require 'ofx_client'
require 'qif_parser'

%w{ account scrapers/base scrapers/paypal scrapers/ofx scrapers/capital_one adapters/base adapters/paypal adapters/ofx adapters/qif }.each do |lib|
  require "bank_agent/" + lib
end

module BankAgent
  class << self
    attr_reader :config
    def config=(path)
        @config = YAML.load(File.read(path))
    end

    def by_name(name)
        config['accounts'].select {|a| a['name'] == name }
    end
  end
end
