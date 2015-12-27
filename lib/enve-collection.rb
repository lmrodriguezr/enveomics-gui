require "enve-task"
require "enve-json"
require "enve-example"

class EnveCollection
   #= Class-level
   @@HOME = nil
   def self.home
      if @@HOME.nil?
	 if ENV["HOME"].nil?
	    if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
	       ENV["HOME"] = "%USERPROFILE%"
	    else
	       # This should never happen, though
	       ENV["HOME"] = "~"
	    end
	 end
	 @@HOME = File.expand_path(".enveomics", ENV["HOME"])
	 Dir.mkdir(@@HOME) unless Dir.exist? @@HOME
      end
      @@HOME
   end
   def self.setup_bins
      # Only for packaged apps
      return if __FILE__ !~ /\.jar!\//
      # Copy bins
      FileUtils.cp_r(File.expand_path("../../bin", __FILE__), home)
      FileUtils.chmod("u=rwx,go=rx", Dir[File.expand_path("bin/*/*", home)]) 
      # Tell the system
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
	 ENV["PATH"] = "#{File.expand_path("bin/windows", home)}:#{ENV["PATH"]}"
      elsif RbConfig::CONFIG['host_os'] =~ /darwin/
	 ENV["PATH"] = "#{File.expand_path("bin/mac", home)}:#{ENV["PATH"]}"
      elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
	 ENV["PATH"] = "#{File.expand_path("bin/linux", home)}:#{ENV["PATH"]}"
      end
   end
   def self.manif
      manif = File.expand_path("enveomics-master/manifest.json", home)
      return manif if File.exist? manif
      nil
   end
   def self.master_url
      "https://github.com/lmrodriguezr/enveomics/archive/master.zip"
   end
   
   #= Instance-level
   attr_accessor :hash, :manif, :examples
   def initialize(manif=nil)
      manif ||= EnveCollection.manif
      @manif = manif
      @hash = EnveJSON.parse(manif)
      
      @hash[:categories] ||= {}
      unless hash[:tasks].nil?
	 @tasks = Hash[hash[:tasks].map do |h|
	    t = EnveTask.new(h)
	    [t.task, t]
	 end]
      end
      unless hash[:examples].nil?
	 @examples = hash[:examples].map { |i| EnveExample.new(i,self) }
      end
      raise "Impossible to initialize collection with empty manifest: " +
	 "#{manif}." if @tasks.nil?
   end
   def tasks
      @tasks.values
   end
   def task(name)
      @tasks[name]
   end
   def each_category(&blk)
      hash[:categories].each do |name,set|
	 blk[name, set]
      end
   end
   def category(name)
      @hash[:categories][name.to_sym] ||= {}
      hash[:categories][name.to_sym]
   end
   def each_subcategory(cat_name, &blk)
      category(cat_name).each do |name,set|
	 blk[name, set]
      end
   end
   def subcategory(cat_name, name)
      category(cat_name)[name.to_sym]
   end
end
