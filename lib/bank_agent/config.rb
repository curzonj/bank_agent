module BankAgent
  class Config
    class << self
      attr_reader :current
      def selfload(path)
        @current = YAML.load(File.read(path))
      end
    end

    def initialize(path)
      @config = 
    end

    def each(&block)
      config['accounts'].each(&block)
    end
  end
end
