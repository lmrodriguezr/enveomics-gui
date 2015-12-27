require "json"

class EnveJSON
   # Class-level
   def self.parse(file)
      EnveJSON.new(file).to_h
   end
   
   # Instance-level
   attr_accessor :file, :hash
   def initialize(file, parse=true, hash={})
      @file = file
      @hash = hash.dup
      if parse
	 h = JSON.parse(File.read(file), {symbolize_names: true})
	 @hash = parse_hash(h)
      end
   end
   
   def +(obj)
      o = EnveJSON.new(file, false, hash)
      return o if obj.nil?
      h = obj.is_a?(EnveJSON) ? obj.hash : obj
      raise "Unsupported operation of EnveJSON + #{obj.class}." unless
	 h.is_a? Hash
      h.each do |k,v|
	 case o[k]
	    when Array, EnveJSON
	       o[k] += v
	    when Hash
	       o[k] = (EnveJSON.new(file, false, o[k]) + v).to_h
	    else
	       o[k] = v
	 end
      end
      o
   end

   def to_h
      deparse_hash(hash)
   end

   def to_json
      to_h.to_json
   end

   private
      
      def parse_hash(h)
	 o = EnveJSON.new(file, false)
	 h.each do |k,v|
	    case k
	       when :_
		  # This is a comment, do nothing
	       when :_include
		  # Include additional file(s)
		  v = [v].flatten
		  v = v.map{|i| Dir[File.expand_path(i, File.dirname(file))]}
		  v.flatten.each do |f|
		     o += EnveJSON.new(f)
		  end
	       else
		  o[k] = parse_value(v)
	    end
	 end
	 o.hash
      end

      def parse_value(v)
         case v
	    when Hash
	       parse_hash(v)
	    when Array
	       v.map{ |i| parse_value i }
	    else
	       v
	 end
      end

      def deparse_hash(h)
	 o = {}
	 h.each do |k,v|
	    o[k] = deparse_value(v)
	 end
	 o
      end

      def deparse_value(v)
	 case v
	    when Hash
	       deparse_hash(v)
	    when Array
	       v.map{ |i| deparse_value i }
	    else
	       v
	 end
      end
end
