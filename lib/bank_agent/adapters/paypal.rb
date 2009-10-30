module BankAgent::Adapters
  class Paypal < Base
    def import_options(line)
      amount = line[' Amount'].gsub(',','')
      balance = line[' Balance'].gsub(',','')

      {
        :payee_name => line[' Name'],
        :amount => BigDecimal.new(amount),
        :recorded_on => Date.parse(line['Date']),
        :memo => line[' Type'],
        :balance => BigDecimal.new(balance),
      }
    end

    def transactions
      # The importer needs them generally oldest first for rare order dependencies
      # and fasterCSV doesn't actually return and array, but it responds to collect
      @csv_data ||= FasterCSV.parse(@raw_data, :headers => true).collect {|t| t }.reverse
    end
  end
end
