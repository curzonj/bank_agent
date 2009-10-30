module BankAgent::Adapters
  class Base
    def initialize(data, opts={})
      @raw_data = data
      @options = opts
    end

    def import_transactions
      transactions.each do |t|
        opts = import_options(t)

        puts opts.inspect
        #Transaction.create!(opts) unless exists?(opts)
      end

      #record_balance

      #unless self.financial_account.nil?
      #  self.financial_account.send_later(:build_balances)
      #end
    end

    def record_balance
      raise NotImplementedError
    end

    def exists?(opts)
      conds = opts.collect do |k,v|
        next unless [ :financial_account_id,
                      :payee_name,
                      :recorded_on,
                      :amount,
                      :check_number
                    ].include?(k)

        # MYSQL is doing case insensitive compares
        if v.is_a?(String)
          "LOWER(#{k}) = '#{v.downcase}'"
        elsif v.nil?
          "(#{k} IS NULL OR #{k} = '')"
        else
          "#{k} = '#{v}'"
        end
      end.compact.join(' AND ')

      !Transaction.find(:first, :conditions => conds).nil?
    end
  end
end
