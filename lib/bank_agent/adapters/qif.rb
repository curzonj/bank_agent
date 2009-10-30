module BankAgent::Adapters
  class Qif < Base
    def import_options(qif)
      amount = qif['transaction'].gsub(',','')

      {
        :payee_name => qif['payee'],
        :recorded_on => qif['date'],
        :amount => BigDecimal.new(amount),
        :check_number => qif['number'],
        :memo => qif['memo']
      }
    end

    def transactions
      acct = qif_data.accounts.first['name'] rescue nil
      qif_data.transactions(acct)
    end

    def qif_data
      @qif_data ||= QifParser.new(@raw_data)
    end
  end
end
