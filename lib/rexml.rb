require 'libxml'
require 'rexml-dropin/element'
require 'rexml-dropin/document'
require 'rexml-dropin/parsers/sax2parser'

module Kernel
  alias :require_rexml_old :require

  def require(path)
    if path =~ /^rexml\//
      $stderr.puts "REXML drop-in: omitting #{path}"
      false
    else
      $stderr.puts "require #{path}"
      require_rexml_old path
    end
  end
end
