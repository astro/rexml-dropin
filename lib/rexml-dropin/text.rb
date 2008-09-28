module REXML
  class Text < String
    def initialize(s, unused1=nil, unused2=nil, unused3=nil)
      super(s)
    end

    def value
      to_s
    end
  end
end
