require 'rexml-dropin/attributes'

module REXML
  class Element
    attr_reader :node
    attr_accessor :context # dummy

    def initialize(arg0)
      if arg0.kind_of? LibXML::XML::Node
        @node = arg0
      elsif arg0.kind_of? Element
        @node = arg0.node
      elsif arg0.kind_of? String
        @node = LibXML::XML::Node::new_element(arg0)
      else
        raise "Unsupported Element initializer: #{arg0.inspect}"
      end

      # HACK: make monkeypatches happy
      @name = @node.name
      @context = nil
    end

    def name
      @node.name
    end

    def deep_clone
      Element.new(@node.copy(true))
    end

    def add(child)
      element = Element.new(child)
      Element.new @node.child_add(element.node.copy(true))
    end
    alias :add_element :add

    ##
    # expr: only element name for now
    def each(expr=nil, &block)
      @node.each_element do |node|
        if expr.nil? or node.name == expr
          block.call Element.new(node)
        end
      end
    end
    alias :each_element :each

    ##
    # expr: only element name for now
    def delete_element(expr=nil)
      @node.each_element do |node|
        if expr.nil? or node.name == expr
          node.remove!
        end
      end
    end

    def children
      @node.children.collect do |child|
        case child.node_type
        when LibXML::XML::Node::ELEMENT_NODE
          Element.new(child)
        when LibXML::XML::Node::TEXT_NODE 
          child.content
        else
          nil
        end
      end
    end

    def attributes
      Attributes.new @node.attributes
    end

    def add_attribute(name, value)
      attributes[name] = value
    end

    def add_attributes(attributes)
      attributes = attributes.to_a if attributes.kind_of? Hash
      attributes.each do |*attribute|
        if attribute.size > 1
          add_attribute attribute[0], attribute[1]
        else
          add_attribute attribute[0].name, attribute[0].value
        end
      end
    end

    ##
    # Returns a LibXML::XML::Attr because it has #name and #value too
    def attribute(name, namespace=nil)
      unless namespace
        @node.attributes.get_attribute(name)
      else
        @node.attributes.get_attribute_ns(namespace, name)
      end
    end

    def each_attribute(&block)
      @node.attributes.each &block
    end

    def add_namespace(prefix, uri=nil)
      unless uri
        @node.namespace = LibXML::XML::NS.new(@node, prefix || '', '')
      else
        LibXML::XML::NS.new(@node, uri, prefix)
      end
    end

    def text
      @node.content
    end

    def text=(text)
      @node.each do |node|
        node.remove! if node.node_type == LibXML::XML::Node::TEXT_NODE
      end

      add_text text
    end

    def add_text(text)
      if text
        @node.child_add LibXML::XML::Node::new_text(text)
      end
    end

    def namespace(prefix='')
      (@node.ns || []).each do |ns|
        if ns.prefix == prefix
          return ns.href
        end
      end
      ''
    end

    def namespaces
      (@node.ns || []).collect { |ns| ns.href }
    end

    def prefixes
      (@node.ns || []).collect { |ns| ns.prefix }
    end

    ##
    # Only first argument used for now
    def write( output=$stdout, indent=-1, trans=false, ie_hack=false )
      output << to_s
    end

    def to_s
      @node.to_s
    end
  end
end
