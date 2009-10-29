module BankAgent
  class Ofx < Base
    def record_balance
      t = transactions.first
      trans = financial_account.transactions.find_by_ofx_fit_id(t.fit_id)

      if trans.nil?
        logger.error("Failed to find transaction #{t.fit_id} to record balance")
      else
        trans.record_balance!(balance, self)
      end
    end

    def import_options(record)
      {
        :payee_name => record.payee,
        :financial_account_id => self.related_account_id,
        :amount => BigDecimal.new(record.amount),
        :check_number => record.check_number,
        :recorded_on => record.date.to_s,
        :ofx_fit_id => record.fit_id,
        :memo => record.memo
      }
    end

    def exists?(opts)
      related_account.transactions.exists?(:ofx_fit_id => opts[:ofx_fit_id])
    end

    def related_account_id
      # TODO
      0

      #@related ||= if self.financial_account.nil? && !ofx_data.nil? 
      #  FinancialAccount.find_new_account(account_number, routing_number)
    end

    def transactions
      @sorted_transactions ||= begin
        ofx_transactions.sort do |a,b|
          sort1 = (b.date <=> a.date)
          sort1 == 0 ? (b.fit_id <=> a.fit_id) : sort1
        end
      end
    end

    def ofx_transactions
      case ofx_type
      when :bank
        ofx_data.bank_account.statement.transactions
      when :ccard
        ofx_data.credit_card.statement.transactions
      end
    end

    def ofx_type
      if !ofx_data.bank_account.nil?
        :bank
      elsif !ofx_data.credit_card.nil?
        :ccard
      end
    end

    def ofx_data
      @ofx_data ||= OfxParser::OfxParser.parse(@raw_data)
    end

    def account_number
      case ofx_type
      when :bank
        ofx_data.bank_account.number
      when :ccard
        ofx_data.credit_card.number
      end
    end

    def balance
      value = case ofx_type
      when :bank
        ofx_data.bank_account.balance_in_pennies
      when :ccard
        ofx_data.credit_card.balance_in_pennies
      end

      BigDecimal.new(value.to_s) / 100
    end

    def routing_number
      case ofx_type
      when :bank
        ofx_data.bank_account.routing_number
      when :ccard
        ""
      end
    end

  end
end
