require "enve-option"
require "enve-requires"
require "enve-job"

class EnveTask
   %w[RUBY AWK PERL BASH RSCRIPT].each do |i|
      class_variable_set("@@#{i}", i.downcase)
      define_singleton_method(i){ class_variable_get("@@#{i}") }
   end
   @@RUBY = "jruby" unless system("#{@@RUBY} -e '{a:1}'")
   @@AWK = "gawk" unless system("#{@@AWK} 'BEGIN{exit}'")
   @@AWK = "mawk" unless system("#{@@AWK} 'BEGIN{exit}'")
   @@RSCRIPT = "Rscript"
   if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      @@BASH = "bash.exe" unless system("#{@@BASH} --version")
      @@BASH = "sh.exe" unless system("#{@@BASH} --version")
      @@AWK = "awk.exe" unless system("#{@@AWK} 'BEGIN{exit}'")
      @@AWK = "gawk.exe" unless system("#{@@AWK} 'BEGIN{exit}'")
      @@AWK = "mawk.exe" unless system("#{@@AWK} 'BEGIN{exit}'")
   end
   attr_accessor :hash
   def initialize(o)
      @hash = o
      raise "task field required to set EnveTask." if @hash[:task].nil?
      @hash[:options] ||= []
   end
   def task
      hash[:task]
   end
   def description
      if hash[:description].is_a? Array
	 @hash[:description] = hash[:description].join(" ")
      end
      hash[:description]
   end
   def help_arg
      hash[:help_arg]
   end
   def options
      @options ||= hash[:options].map{ |o| EnveOption.new(o) }
      @options
   end
   def each_option(&blk)
      i=0
      options.each do |o|
	 blk.arity==1 ? blk[o] : blk[i,o]
	 i+=1
      end
   end
   def requires
      if @requires.nil?
	 @hash[:requires] ||= []
	 @hash[:requires].unshift({interpreter: interpreter})
	 @requires = hash[:requires].map{ |r| EnveRequires.new(r) }
      end
      @requires
   end
   def interpreter
      if @interpreter.nil?
	 regex_hash = {
	    /\.rb$/ => "ruby", /\.pl$/ => "perl",
	    /\.[Rr](script)?$/ => "Rscript",
	    /\.g?awk$/ => "awk", /\.(ba)?sh$/ => "bash" }
	 @interpreter = regex_hash.map{ |k,v| v if k =~ task }.compact.first
	 abort "Unknown interpreter for #{task}." if @interpreter.nil?
      end
      @interpreter
   end
   def ready?
      requires.map{ |r| r.pass? }.all?
   end
   def unmet
      requires.select{ |r| not r.pass? }
   end
   def explicit_task?
      options.map{ |o| o.arg==:task }.any?
   end
   def warn
      @hash[:warn] ||= ""
      @hash[:warn] = hash[:warn].join(" ") if hash[:warn].is_a? Array
      hash[:warn]
   end
   def see_also
      @hash[:see_also] ||= []
      @hash[:see_also] = [hash[:see_also]] unless hash[:see_also].is_a? Array
      hash[:see_also]
   end
   def launch_job(values)
      EnveJob.new(self, values)
   end
end

