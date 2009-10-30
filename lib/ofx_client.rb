require 'net/http'
require 'net/https'

require 'ostruct'

require 'rubygems'
gem 'ofx-parser'
gem 'uuidtools'
gem 'activesupport'

require 'ofx-parser'
require 'activesupport'
require 'uuidtools'

class OfxClient < OpenStruct
  OFX_DATE_FMT = "%Y%m%d"
  OFX_DATETIME_FMT = "%Y%m%d%H%M%S"
  OFX_CLIENT = "Money"
  OFX_VERSION = "1700"
  OFX_ACCT_SINCE = "19700101000000"

  attr_accessor :print_only

  ## Example
  #  OfxClient.new(:fi_type => :ccard,
  #                :fid => 7101)
  #                :fiorg => "Discover Financial Services",
  #                :url => "https://ofx.discovercard.com/",
  #                :username => 'username',
  #                :password => 'password')

  def initialize(*args)
    super(*args)

    [ :fi_type, :fiorg, :url, :username, :password ].each do |arg|
      raise ArgumentError.new("#{arg} is required") unless self.respond_to?(arg)
    end

    unless [ :ccard, :investment, :bank ].include?(self.fi_type)
      raise ArgumentError.new("fi_type must be one of: :ccard, :investment, :bank")
    end

    @cookie = 3
  end

  def account_list
    @account_list_data ||= begin
      req = list(
              header,
              tag("OFX",
                signon_msg_set,
                account_list_msg_set))
      get_response(req)
    end
  end

  def account_numbers
    ofx = OfxParser::OfxParser.parse(account_list)
    ofx.signup_account_info.map(&:number)
  end

  def transaction_data(acct_num, start_date=nil)
    start_date ||= Date.today - 80.days
    @transaction_data ||= {}
    @transaction_data[acct_num] ||= begin
      req = list(
              header,
              tag("OFX",
                signon_msg_set,
                self.send("#{self.fi_type}_msg_set", acct_num, start_date)))
      get_response(req)
    end
  end

  def ccard_msg_set(acct_num, start_date)
    from = start_date.strftime(OFX_DATE_FMT)

    message("CREDITCARD", "CCSTMT",
      tag("CCSTMTRQ",
        tag("CCACCTFROM",
          field("ACCTID", acct_num)),
        tag("INCTRAN",
          field("DTSTART", from),
          field("INCLUDE", "Y"))))
  end

  def investment_msg_set(acct_num)
    raise "Not implemented yet"
  end

  def bank_msg_set(acct_num)
    raise "Not implemented yet"
  end

  #private
  def list(*args)
    args.flatten.join("\r\n")
  end

  def field(name, value)
    "<#{name}>#{value}"
  end

  def tag(tag, *args)
    list("<#{tag}>", args, "</#{tag}>")
  end

  def message(msg_type, trn_type, request)
    tag("#{msg_type}MSGSRQV1",
      tag("#{trn_type}TRNRQ",
        field("TRNUID",uuid),
        field("CLTCOOKIE", cookie),
        request))
  end

  def uuid
    UUIDTools::UUID.timestamp_create.to_s.upcase
  end

  def cookie
    (@cookie += 1).to_s
  end

  def header
    list("OFXHEADER:100",
         "DATA:OFXSGML",
         "VERSION:102",
         "SECURITY:NONE",
         "ENCODING:USASCII",
         "CHARSET:1252",
         "COMPRESSION:NONE",
         "OLDFILEUID:NONE",
         "NEWFILEUID:#{uuid}",
         "")
  end

  def account_list_msg_set
    message("SIGNUP", "ACCTINFO",
      tag("ACCTINFORQ",
        field("DTACCTUP", OFX_ACCT_SINCE)))
  end

  def signon_msg_set
    time = Time.now.strftime(OFX_DATETIME_FMT)

    fidata = [ field("ORG", self.fiorg) ]
    fidata << field("FID", self.fid) unless self.fid.nil?

    tag("SIGNONMSGSRQV1",
      tag("SONRQ",
        field("DTCLIENT",time),
        field("USERID",self.username),
        field("USERPASS",self.password),
        field("LANGUAGE","ENG"),
        tag("FI", *fidata),
        field("APPID",OFX_CLIENT),
        field("APPVER",OFX_VERSION)))
  end

  def get_response(ofx)
    if self.print_only
      puts "*****#{ofx}*******"
      return
    end

    url_parts = URI.parse(self.url)

    http = Net::HTTP.new(url_parts.host, url_parts.port)
    http.use_ssl = true if url_parts.port == 443

    req = Net::HTTP::Post.new(url_parts.path)
    req.content_type = "application/x-ofx"
    req['Accept'] = "*/*, application/x-ofx"

    req.body = ofx

    response = http.request(req)
    raise Net::HTTPError.new('Invalid HTTP response', response) unless response.is_a?(Net::HTTPSuccess)

    response.body
  end
end
