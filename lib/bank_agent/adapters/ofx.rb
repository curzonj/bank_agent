module BankAgent::Adapters
  class Ofx < Base
    def import_options(record)
      {
        :payee_name => record.payee,
        :amount => BigDecimal.new(record.amount),
        :check_number => record.check_number,
        :recorded_on => record.date.to_s,
        :ofx_fit_id => record.fit_id,
        :memo => record.memo
      }
    end

    def account_info
      {
        :number => account_number,
        :routing => routing_number
      }
    end

    def transactions
      @sorted_transactions ||= begin
        ofx_transactions.sort do |a,b|
          sort1 = (a.date <=> b.date)
          sort1 == 0 ? (a.fit_id <=> b.fit_id) : sort1
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

  end
end
