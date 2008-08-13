module REXML
  class Attributes
    def initialize(arg0=nil)
      if arg0.kind_of? LibXML::XML::Attributes
        @attributes = arg0
      else
        raise
      end
    end

    def [](name)
      @attributes[name]
    end

    def []=(name, value)
      if value
        @attributes[name] = value
      elsif attr = @attributes.get_attribute(name)
        attr.remove!
      end
    end

    def each(&block)
      @attributes.each do |attr|
        block.call attr.name, attr.value
      end
    end

    def each_attribute(&block)
      @attributes.each &block
    end
  end
end
