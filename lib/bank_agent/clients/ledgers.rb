require 'httparty'

module Clients
  class Ledgers
    include HTTParty
    format :json

    def initialize(config, options)
      @config = config
      @options = options

      self.class.base_uri @config['base_uri']
      self.class.basic_auth @config['username'], @config['password']
    end

    def import(bank_data)
      account = find_account(bank_data[:account])
      unless account[:balance].blank?
        bank_data[:transactions].last.merge!(
                  :balance => account[:balance],
                  :balance_related_type => 'BankDownload')
      end

      bank_data[:transactions].each do |txn|
        transaction = self.class.create_transaction(
          account,
          'payee_name' => txn[:payee_name],
          'amount' => txn[:amount],
          'check_number' => txn[:check_number],
          'recorded_on' => txn[:recorded_on],
          'ofx_fit_id' => txn[:ofx_fit_id],
          'memo' => txn[:memo])

        puts "Failed to create #{txn[:recorded_on]} #{txn[:payee_name]}" unless transaction
      end
    end

    def find_account(hash)
      opts = {
        'account_number' => hash[:number],
        'routing_number' => hash[:routing]
      }

      account = if @options['account_id']
        self.class.account('id' => @options['account_id'])
      else
        self.class.account(opts)
      end

      if account.nil?
        raise "name is required to create an account" if @options['name'].blank?
        opts['name'] = @options['name'] 
        account = self.class.create_account(opts)
      end

      account
    end

    class << self
      def account(opts)
        result = get("/financial_accounts/find", :query => { :account => opts })
        result['financial_account'] if valid?(result)
      end

      def create_account(opts)
        result = post("/financial_accounts", :query => { :account => opts })
        result['financial_account'] if valid?(result)
      end

      def create_transaction(account, opts)
        opts.delete_if {|k,v| v.blank? }
        result = post("/transactions.json", :query => { :transaction => opts, :financial_account_id => account['id'] })
        result['transaction'] if valid?(result)
      end

      def valid?(result)
        puts result.inspect
        if result.nil?
          raise "Server failed to respond"
        elsif result["HTTP Basic"] == "Access denied."
          raise "Authentication Failed"
        elsif result['error']
          raise result['error']
        elsif result['success'] != false
          true
        end
      end
    end
  end
end
