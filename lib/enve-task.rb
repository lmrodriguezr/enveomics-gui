require "enve-option"

class EnveTask
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
	 if blk.arity==1
	    blk[o]
	 else
	    blk[i,o]
	 end
	 i+=1
      end
   end
   def requires
      @hash[:requires] ||= []
      @requires ||= hash[:requires].map{ |r| EnveRequires.new(r) }
      @requires
   end
   def ready?
      requires.map{ |r| r.pass? }.all?
   end
   def unmet
      requires.select{ |r| not r.pass? }
   end
   def reserve_stderr!
      @reserved_stderr = true
   end
   def reserve_stdout!
      @reserved_stdout = true
   end
   def reserved_stderr?
      !!@reserved_stderr
   end
   def reserved_stdout?
      !!@reserved_stdout
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
   def build_cmd(values, logfile)
      scripts = File.expand_path("enveomics-master/Scripts",EnveCollection.home)
      task_cmd = []
      task_cmd << $EXT_RUBY if task =~ /\.rb$/
      task_cmd << File.expand_path(task, scripts).shellescape
      cmd = []
      each_option do |i,o|
	 if o.arg==:task
	    # Place task here
	    cmd += task_cmd
	    task_cmd = []
	 elsif o.as_is?
	    # As is, unescaped
	    cmd << o.opt
	    reserve_stderr! if o.opt=="2>"
	    reserve_stdout! if o.opt==">"
	 else
	    if o.arg!=:nil and (values[i].nil? or values[i]=="")
	       raise "#{o.name} is mandatory." if o.mandatory?
	       next
	    end
	    case o.arg
	       # Flags
	       when :nil
		  cmd << o.opt.shellescape if values[i]
	       # Numbers
	       when :integer, :float
		  values[i] = o.arg==:integer ? values[i].to_i : values[i].to_f
		  cmd << o.opt.shellescape unless o.opt.nil?
		  cmd << values[i].to_s.shellescape
	       # Strings
	       when :character
		  cmd << o.opt.shellescape unless o.opt.nil?
		  cmd << values[i].to_s[0].shellescape unless o.opt.nil?
	       else
		  cmd << o.opt.shellescape unless o.opt.nil?
		  cmd << values[i].shellescape
	    end
	 end
      end unless values.nil?
      cmd.unshift(*task_cmd)
      cmd << hash[:help_arg] if values.nil? and not hash[:help_arg].nil?
      if reserved_stderr? and reserved_stdout?
	 File.open(logfile.path, "w"){}
      else
	 cmd << ( reserved_stderr? ? ">" :
		  reserved_stdout? ? "2>" :
		  "&>" )
	 cmd << logfile.path.shellescape
      end
      cmd.join(" ")
   end
end


class EnveRequires
   attr_accessor :hash
   def initialize(o)
      @hash = o
      raise "Empty requirement." if
	 @hash[:test].nil? and @hash[:description].nil?
   end
   def pass?
      return true if hash[:test].nil?
      `#{hash[:test]}`==1
   end
   def description
      @hash[:description] ||= hash[:test]
      hash[:description]
   end
   def test
      hash[:test]
   end
end
