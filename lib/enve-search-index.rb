
class EnveSearchIndex
   #- Class-level
   def self.sanitize(text)
      text = string_from_obj(text) unless text.is_a?(String)
      text.gsub(/['"]/,"").gsub(/[^A-Za-z0-9]/," ").downcase.
	 split(/\s+/).compact.map{ |i| i.gsub(/^_+/,"").gsub(/_+$/,"") }.
	 select{ |i| i.length > 1 }.
	 select{ |i|
	    not ["", %w(an and are as at be by can file help if in it no),
	       %w(of or out than the to true with)].flatten.include? i }.
	 uniq
   end
   def self.string_from_obj(h)
      case h
	 when Array
	    h.map{ |i| string_from_obj(i) }.flatten.join(" ")
         when Hash
	    string_from_obj h.values
	 when EnveTask
	    h.task
	 else
	    h.to_s
      end
   end

   #- Instance-level
   attr_accessor :collection
   def initialize(collection, entries=nil)
      @collection = collection
      @entries = entries unless entries.nil?
   end
   def search(text)
      res = self
      EnveSearchIndex.sanitize(text).each do |w|
	 res = EnveSearchIndex.new(collection, res.filter(w))
      end
      res
   end
   def filter(word)
      entries.select { |k,r| r.include? word }
   end
   def index!
      @entries = {}
      collection.tasks.each do |t|
	 id = "script:#{t.task}"
	 @entries[id] ||= EnveSearchResult.new(:script, t.task, self)
	 @entries[id] << t.hash
      end
      collection.each_category do |cat,cat_set|
	 collection.each_subcategory(cat) do |subcat, subcat_set|
	    subcat_set.each do |task|
	       id = "script:#{task}"
	       @entries[id] ||= EnveSearchResult.new(:script, task, self)
	       @entries[id] << cat
	       @entries[id] << subcat
	    end
	 end
      end
      collection.examples.each_index do |i|
	 ex = collection.examples[i]
	 id = "example:#{i}"
	 @entries[id] ||= EnveSearchResult.new(:example, i, self)
	 @entries[id] << ex.description
	 @entries[id] << ex.task
	 @entries[id] << ex.values
      end
   end
   def entries
      index! if @entries.nil?
      @entries
   end
   def each(&blk)
      entries.each do |k,r|
	 if blk.arity==2
	    blk[k,r]
	 else
	    blk[r]
	 end
      end
   end
   def count
      entries.count
   end
end

class EnveSearchResult
   attr_accessor :type, :entry, :terms, :index
   def initialize(type, entry, index)
      @type = type
      @entry = entry
      @index = index
      @terms = []
   end
   def id ; "/#{type}/#{entry}" ; end
   def <<(terms)
      @terms += EnveSearchIndex.sanitize(terms)
   end
   def include?(word)
      terms.any? { |i| i =~ /^#{word}/ }
   end
   def name
      case type.to_sym
	 when :script
	    entry
	 when :example
	    o = index.collection.examples[entry.to_i]
	    o.nil? ? "Empty example" : "Example using #{o.task.task}"
      end
   end
   def description
      case type.to_sym
	 when :script
	    o = index.collection.task(entry)
	    o.nil? ? "" : o.description
	 when :example
	    o = index.collection.examples[entry.to_i]
	    o.nil? ? "" : o.description
      end
   end
end
