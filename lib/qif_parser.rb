class QifParser

  INDICATORS = {
    :noninvestment => {
    "D" => "date",
    "T" => "transaction",
    "U" => "total",         #Quicken 2005 added this which is usually the same
                            #as T but can sometimes be higher.
    "C" => "status",
    "N" => "number",
    "P" => "payee",
    "M" => "memo",
    "A" => "address",
    "L" => "category",
    "S" => "splits"
    },

    :split => {
    "S" => "category",
    "E" => "memo",
    '$' => "amount"
    },

    :investment => {
    "D" => "date",
    "N" => "action",
    "Y" => "security",
    "I" => "price",
    "Q" => "quantity",
    "T" => "transaction",
    "U" => "total",        #Quicken 2005 added this which is usually the same as
                           #as T but can sometimes be higher.
    "C" => "status",
    "P" => "text",
    "M" => "memo",
    "O" => "commission",
    "L" => "account",
    '$' => "amount"
    },

    :account => {
    "N" => "name",
    "D" => "description",
    "L" => "limit",
    "X" => "tax",
    "A" => "note",
    "T" => "type",
    "B" => "balance"
    },

    :category => {
    "N" => "name",
    "D" => "description",
    "B" => "budget",
    "E" => "expense",
    "I" => "income",
    "T" => "tax",
    "R" => "schedule"
    },

    :class => {
    "N" => "name",
    "D" => "description"
    },

    :memorized => {
    "K" => "type",
    "T" => "transaction",
    "U" => "total",        #Quicken 2005 added this which is usually the same as
                           #as T but can sometimes be higher.
    "C" => "status",
    "P" => "payee",
    "M" => "memo",
    "A" => "address",
    "L" => "category",
    "S" => "splits",
    "N" => "action",       #Quicken 2006 added N, Y, I, Q, $ for investment
    "Y" => "security",
    "I" => "price",
    "Q" => "quantity",
    '$' => "amount",
    "1" => "first",
    "2" => "years",
    "3" => "made",
    "4" => "periods",
    "5" => "interest",
    "6" => "balance",
    "7" => "loan"
    },

    :security => {
    "N" => "security",
    "S" => "symbol",
    "T" => "type",
    "G" => "goal",
    },

    :budget => {
    "N" => "name",
    "D" => "description",
    "E" => "expense",
    "I" => "income",
    "T" => "tax",
    "R" => "schedule",
    "B" => "budget"
    },

    :payee => {
    "P" => "name",
    "A" => "address",
    "C" => "city",
    "S" => "state",
    "Z" => "zip",
    "Y" => "country",
    "N" => "phone",
    "#" => "account"
    },

    :prices => {
    "S" => "symbol",
    "P" => "price"
    },

    :price => {
    "C" => "close",
    "D" => "date",
    "X" => "max",
    "I" => "min",
    "V" => "volume"
    }
  }

  HEADERS = {
  "Type:Bank"         => :noninvestment,
  "Type:Cash"         => :noninvestment,
  "Type:CCard"        => :noninvestment,
  "Type:Oth A"        => :noninvestment,
  "Type:Oth L"        => :noninvestment,
  "Type:Invst"        => :investment,

  "Account"           => :account,
  "Type:Cat"          => :category,
  "Type:Class"        => :class,
  "Type:Memorized"    => :memorized,
  "Type:Security"     => :security,
  "Type:Budget"       => :budget,
  "Type:Payee"        => :payee,
  "Type:Prices"       => :prices,
  :split              => :split,

  "Option:AutoSwitch" => nil,
  "Option:AllXfr"     => nil,
  "Clear:AutoSwitch"  => nil
  }

  def initialize(data)
    parse(data)
  end

  def bank_transactions
    set('Type:Bank')
  end

  def parseline(line)
    [ line[0..0], line[1..1000].strip ]
  end

  def set(header)
    @set ||= {}
    @set[header] ||= []
  end

  def accounts
    @accounts ||= []
  end

  def transactions(acct)
    @transactions ||= {}
    @transactions[acct] ||= []
  end

  def translate(header, key=nil)
    # Some headers are just broken
    record_type = HEADERS[header] || :noninvestment
    val = INDICATORS[record_type][key] rescue nil

    key.nil? ? record_type : val
  end

  def parse_date(v)
    if v.match(/\d{1,2}\/\d{1,2}\/\d{4}/)
      Date.parse(v)
    else
      md, y = v.split("'")
      m, d = md.split("/")
      Date.parse("#{m}/#{d}/#{y.to_i + 2000}")
    end
  rescue
    puts "Error parsing: #{v}"
    return v
  end

  def parse(data)
    header = nil
    record = {}
    split = nil
    last_account = nil

    data.split("\n").each_with_index do |line, line_no|
      field, value = parseline(line)

      case field
      when '!'
        header = value.strip
      when '^'
        if [:noninvestment, :investment ].include?(translate(header))
          transactions(last_account) << record
        elsif [ :account ].include?(HEADERS[header])
          last_account = record['name']
          accounts << record
        else
          set(header) << record
        end

        record = {}
        split = nil
      else
        if field == 'S' && translate(header, field) == 'splits'
          split = {}
          
          k = translate(:split, field)
          split[k] = value
          record['splits'] ||= []
          record['splits'] << split
        elsif (field == 'E' || field == '$') && !split.nil?
          k = translate(:split, field)
          split[k] = value
        else
          k = translate(header, field)
          raise "unknown field #{field} for #{header} on line:#{line_no}" if k.nil?
          value = parse_date(value) if k == 'date' and !value.blank?
          record[k] = value
        end
      end
    end

    @set
  end
end
