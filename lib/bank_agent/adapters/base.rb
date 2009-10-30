module BankAgent::Adapters
  class Base
    def initialize(data)
      @raw_data = data
    end

    def bank_data
      {
        :account => account_info.merge(:balance => balance),
        :transactions => parsed_transactions.compact
      }
    end

    def parsed_transactions
      transactions.map {|t| import_options(t) }
    end

    def import_options(data)
      nil
    end

    def account_info
      {}
    end

    def balance
      nil
    end
  end
end
