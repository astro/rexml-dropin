module REXML
  class Attribute
    def initialize(attr)
      @attr = attr
    end

    def name
      @attr ? @attr.name : nil
    end

    def value
      @attr ? @attr.value : nil
    end

    def to_s
      @attr ? @attr.value.to_s : ''
    end
  end
end
