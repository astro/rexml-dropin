require 'rexml-dropin/attributes'
require 'rexml-dropin/attribute'

module REXML
  class Element
    attr_reader :node
    attr_accessor :context # dummy

    ##
    # The @instance injected into the @node serves for preserving
    # classes and objects when custom REXML::Element-derived classes
    # are added as children and later retrieved.
    def Element.new(*args)
      if args.size == 1 and
          args[0].kind_of? LibXML::XML::Node and
          args[0].instance_variable_defined? :@instance
        puts "Reviving instance #{args[0].instance_variable_get(:@instance).inspect}"
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

    def name
      @node.name
    end

    def deep_clone
      Element.new(@node.copy(true))
    end

    def add(child)
      node = Element.new(child).node
      if node.parent?
        node.remove!
      end
      Element.new @node.child_add(node)
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

    def add_namespace(prefix, uri=nil)
      prefix ||= ''
      uri, prefix = prefix, nil unless uri

      LibXML::XML::NS.new(@node, uri, prefix)
    end

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
        @node.child_add LibXML::XML::Node::new_text(text)
      end

      self
    end

    def namespace(prefix=nil)
      prefix ||= ''
      (@node.ns || []).each do |ns|
        if ns.prefix.to_s == prefix
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
