require 'rexml-dropin/attributes'
require 'rexml-dropin/attribute'
require 'rexml-dropin/text'
require 'rexml-dropin/cdata'

module REXML
  class Element
    attr_reader :libxml_node
    attr_accessor :context # dummy

    ##
    # Constructor functions
    ##

    ##
    # The @instance injected into the @node serves for preserving
    # classes and objects when custom REXML::Element-derived classes
    # are added as children and later retrieved.
    def Element.new(*args)
      if args.size == 1 and
          args[0].kind_of? LibXML::XML::Node and
          args[0].instance_variable_defined? :@instance
        #puts "Reviving instance #{args[0].instance_variable_get(:@instance).inspect}"
        args[0].instance_variable_get :@instance
      else
        super
      end
    end

    def initialize(arg0)
      if arg0.kind_of? LibXML::XML::Node
        @libxml_node = arg0
      elsif arg0.kind_of? Element
        @libxml_node = arg0.libxml_node
      elsif arg0.kind_of? String
        @libxml_node = LibXML::XML::Node::new_element(arg0)
      else
        raise "Unsupported Element initializer: #{arg0.inspect}"
      end

      raise 'Shalt not happen!' if instance_variable_defined? :@instance
      @libxml_node.instance_variable_set(:@instance, self)

      # HACK: make monkeypatches happy
      @name = @libxml_node.name
      @context = nil
    end

    def deep_clone
      Element.new(@libxml_node.copy(true))
    end

    ##
    # Children functoins
    ##

    def add(child)
      if child.kind_of? CData
        add_cdata child
      elsif child.kind_of? Text
        add_text child
      else
        element = child.kind_of?(Element) ? child : Element.new(child)
        if element.libxml_node.parent?
          element.libxml_node.remove!
        end
        @libxml_node.child_add(element.libxml_node)
        element
      end
    end
    alias :add_element :add

    ##
    # expr: only element name for now
    def each_element(expr=nil, &block)
      @libxml_node.each_element do |node|
        if expr.nil? or node.name == expr
          block.call Element.new(node)
        end
      end
    end

    def each(expr=nil, &block)
      if expr
        each_element(expr, &block)
      else
        @libxml_node.each do |node|
          case node.node_type
          when LibXML::XML::Node::ELEMENT_NODE
            block.call Element.new(node)
          when LibXML::XML::Node::TEXT_NODE 
            block.call Text.new(node.content)
          end
        end
      end
    end

    ##
    # expr: only element name or instance for now
    def delete_element(what=nil)
      @libxml_node.each_element do |node|
        if what.nil? or node.name == what or
            (what.kind_of? Element and what.libxml_node == node)
          node.remove!
        end
      end
    end

    def children
      @libxml_node.children.collect do |child|
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

    def parent
      @libxml_node.parent ? Element.new(@libxml_node.parent) : nil
    end

    ##
    # Attribute functions
    ##

    def attributes
      Attributes.new @libxml_node.attributes
    end

    def add_attribute(name, value)
      if name == 'xmlns'
        add_namespace value
      elsif name == /^xmlns:(.+)$/
        add_namespace $1, value
      else
        attributes[name] = value
      end
    end

    def add_attributes(attributes)
      attributes.each do |*attribute|
        if attribute.size > 1
          add_attribute attribute[0], attribute[1]
        elsif attribute[0].kind_of? Attribute
          add_attribute attribute[0].name, attribute[0].value
        elsif attribute[0].kind_of? Array
          add_attribute attribute[0][0], attribute[0][1]
        else
          raise "Invalid attribute: #{attribute.inspect}"
        end
      end
    end

    def attribute(name, namespace=nil)
      unless namespace
        attr = @libxml_node.attributes.get_attribute(name)
      else
        attr = @libxml_node.attributes.get_attribute_ns(namespace, name)
      end
      attr ? Attribute.new(attr) : nil
    end

    def each_attribute(&block)
      @libxml_node.attributes.each do |attr|
        block.call Attribute.new(attr)
      end
    end

    ##
    # Text content
    ##

    def text
      t = @libxml_node.content
      t.empty? ? nil : t
    end

    def text=(text)
      @libxml_node.each do |node|
        node.remove! if node.node_type == LibXML::XML::Node::TEXT_NODE
      end

      add_text text

      text
    end

    def add_text(text)
      if text
        @libxml_node.child_add LibXML::XML::Node::new_text(text.to_s)
      end

      self
    end

    ##
    # Cdata content
    ##

    def cdatas
      r = []
      @libxml_node.each do |child|
        if child.node_type == LibXML::XML::Node::CDATA_SECTION_NODE
          r << CData.new(child.content)
        end
      end
      r
    end

    def add_cdata(text)
      @libxml_node.child_add LibXML::XML::Node::new_cdata(text.to_s)
      self
    end
    ##
    # Namespace functions
    ##

    def add_namespace(prefix, uri=nil)
      # Avoid adding no namespace as empty namespace:
      return unless prefix
      # Add default namespace:
      uri, prefix = prefix, nil unless uri

      LibXML::XML::NS.new(@libxml_node, uri, prefix)
    end

    def namespace(prefix=nil)
      (@libxml_node.ns || []).each do |ns|
        if ns.prefix == prefix
          #puts "Returning #{ns.href.inspect} from #{inspect}"
          return ns.href
        end
      end
      ''
=begin
      # None found? Try parent
      puts "Going up from #{inspect}"
      if @libxml_node.parent
        Element.new(@libxml_node.parent).namespace prefix
      else
        ''
      end
=end
    end

    def delete_namespace(prefix=nil)
=begin
      (@libxml_node.ns || []).each { |ns|
        if ns.prefix == prefix
          # Is not implemented:
          ns.remove!
        end
      }
=end
    end

    # TODO: collect from parent
    def namespaces
      (@libxml_node.ns || []).collect { |ns| ns.href }
    end

    # TODO: collect from parent
    def prefixes
      (@libxml_node.ns || []).collect { |ns| ns.prefix }
    end

    ##
    # Serialization
    ##

    def name
      prefix, name = @libxml_node.name.split(':', 2)
      name ? name : prefix
    end

    def name=(s)
      # TODO: prefix?
      @libxml_node.name = @name = s
    end

    # You are doing it wrong.
    def prefix
      prefix, name = @libxml_node.name.split(':', 2)
      name ? prefix : nil
    end

    def whitespace
      nil
    end

    ##
    # Only first argument used for now
    def write( output=$stdout, indent=-1, trans=false, ie_hack=false )
      output << to_s
    end

    def to_s
      @libxml_node.to_s
    end

    def inspect
      "#{to_s}:#{self.class}"
    end

  end
end
