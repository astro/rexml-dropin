module REXML
  module Parsers
    class SAX2Parser
      def initialize(source)
        @source = source
        @listeners = []
        @parser = LibXML::XML::SaxParser.new
      end

      def parse
        if @source.kind_of? String
          @parser.string = @source
          @parser.parse
        elsif @source.respond_to? :read
          while buf = @source.readline('>')
            @parser.string = buf
            @parser.parse
          end
        else
          raise "Unsupported source: #{@source.inspect}"
        end
      end

      ##
      # Only with Symbol, not Array for now
      def listen(symbol, &block)
        @listeners << [symbol, block]
      end

      def call_listeners(event, *args)
        @listeners.each do |symbol,block|
          if event == symbol
            block.call(*args)
          end
        end
      end

      include LibXML::XML::SaxParser::Callbacks


      def on_start_document
      end

      def on_start_element(name, attr_hash)
        call_listeners(:start_element, nil, name, name, attr_hash)
      end
      
      def on_characters(chars)
        call_listeners(:characters, chars)
      end
      
      def on_comment(msg)
      end
      
      def on_processing_instruction(target, data)
      end
      
      def on_cdata_block(cdata)
        call_listeners(:cdata, cdata)
      end
      
      def on_end_element(name)
        call_listeners(:end_element, nil, name, name)
      end
      
      def on_end_document
      end
      
    end
  end
end
