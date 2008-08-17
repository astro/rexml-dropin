require 'rexml-dropin/attributes'
require 'rexml-dropin/attribute'
require 'rexml-dropin/text'
require 'rexml-dropin/cdata'

module REXML
  class Element
    attr_reader :node
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
        @node = arg0
      elsif arg0.kind_of? Element
        @node = arg0.node
      elsif arg0.kind_of? String
        @node = LibXML::XML::Node::new_element(arg0)
      else
        raise "Unsupported Element initializer: #{arg0.inspect}"
      end

      raise 'Shalt not happen!' if instance_variable_defined? :@instance
      @node.instance_variable_set(:@instance, self)

      # HACK: make monkeypatches happy
      @name = @node.name
      @context = nil
    end

    def deep_clone
      Element.new(@node.copy(true))
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
        if element.node.parent?
          element.node.remove!
        end
        @node.child_add(element.node)
        element
      end
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
    # expr: only element name or instance for now
    def delete_element(what=nil)
      @node.each_element do |node|
        if what.nil? or node.name == what or
            (what.kind_of? Element and what.node == node)
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

    def parent
      @node.parent ? Element.new(@node.parent) : nil
    end

    ##
    # Attribute functions
    ##

    def attributes
      Attributes.new @node.attributes
    end

    def add_attribute(name, value)
      attributes[name] = value
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
        attr = @node.attributes.get_attribute(name)
      else
        attr = @node.attributes.get_attribute_ns(namespace, name)
      end
      attr ? Attribute.new(attr) : nil
    end

    def each_attribute(&block)
      @node.attributes.each do |attr|
        block.call Attribute.new(attr)
      end
    end

    ##
    # Text content
    ##

    def text
      t = @node.content
      t.empty? ? nil : t
    end

    def text=(text)
      @node.each do |node|
        node.remove! if node.node_type == LibXML::XML::Node::TEXT_NODE
      end

      add_text text

      text
    end

    def add_text(text)
      if text
        @node.child_add LibXML::XML::Node::new_text(text.to_s)
      end

      self
    end

    ##
    # Cdata content
    ##

    def cdatas
      r = []
      @node.each do |child|
        if child.node_type == LibXML::XML::Node::CDATA_SECTION_NODE
          r << CData.new(child.content)
        end
      end
      r
    end

    def add_cdata(text)
      @node.child_add LibXML::XML::Node::new_cdata(text.to_s)
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

      LibXML::XML::NS.new(@node, uri, prefix)
    end

    def namespace(prefix=nil)
      (@node.ns || []).each do |ns|
        if ns.prefix == prefix
          #puts "Returning #{ns.href.inspect} from #{inspect}"
          return ns.href
        end
      end
      ''
=begin
      # None found? Try parent
      puts "Going up from #{inspect}"
      if @node.parent
        Element.new(@node.parent).namespace prefix
      else
        ''
      end
=end
    end

    # TODO: collect from parent
    def namespaces
      (@node.ns || []).collect { |ns| ns.href }
    end

    # TODO: collect from parent
    def prefixes
      (@node.ns || []).collect { |ns| ns.prefix }
    end

    ##
    # Serialization
    ##

    def name
      prefix, name = @node.name.split(':', 2)
      name ? name : prefix
    end
    # When name= is being implemented, watch out for @name instance
    # variable!

    # You are doing it wrong.
    def prefix
      prefix, name = @node.name.split(':', 2)
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
      @node.to_s
    end

    def inspect
      "#{to_s}:#{self.class}"
    end

  end
end
