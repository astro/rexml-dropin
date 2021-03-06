require 'rexml-dropin/parseexception'
require 'xml/parser'

module REXML
  module Parsers
    class SAX2Parser < XML::Parser
      def SAX2Parser.new(source)
        o = super('UTF-8')
        o.instance_eval { initialize source }
        o
      end

      def initialize(source)
        @source = source
        @listeners = []
        @in_cdata = false
        super()
      end

      def parse
        begin
          if @source.kind_of? String
            #puts "Parsing #{@source.inspect}"
            super @source, true
          elsif @source.respond_to? :readline
            while buf = @source.readline('>')
              #puts "Parse #{buf.inspect}"
              super buf, false
            end
            #puts "everything from #{@source.inspect}"
          else
            raise "Unsupported source: #{@source.inspect}"
          end
        rescue XMLParserError => e
          raise ParseException.new(e.to_s)
        end
        #puts "Parsed"
      end

      ##
      # Only with Symbol, not Array for now
      def listen(symbol, &block)
        @listeners << [symbol, block]
      end

      def call_listeners(event, *args)
        #puts "call_listeners(#{event.inspect}, #{args.inspect})"
        @listeners.each do |symbol,block|
          if event == symbol
            block.call(*args)
          end
        end
      end

      def startElement(name, attr_hash)
        call_listeners(:start_element, nil, name, name, attr_hash)
      end
      
      def endElement(name)
        call_listeners(:end_element, nil, name, name)
      end
      
      def character(chars)
        if @in_cdata
          call_listeners(:cdata, chars)
        else
          call_listeners(:characters, chars)
        end
      end

      def startCdata
        @in_cdata = true
      end

      def endCdata
        @in_cdata = false
      end

      def unknownEncoding(e)
        XML::Encoding.new
      end
  
    end
  end
end
