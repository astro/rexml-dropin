require 'rexml-dropin/element'

module REXML
  class Document
    attr_accessor :root

    def initialize(source=nil)
      @root = nil

      if source
        buf = ''

        if source.kind_of? File
          buf = source.readlines.join('')
        elsif source.kind_of? String
          buf = source
        else
          raise "Unsupported source: #{source.inspect}"
        end

        parser = LibXML::XML::Parser.new
        parser.string = buf
        @root = Element.new(parser.parse.root)
      end
    end

    ##
    # Only first argument used for now
    def write(output=$stdout, indent=-1, trans=false, ie_hack=false)
      output << @root.to_s
    end
  end
end
