require "open3"
require "tempfile"
require "shellwords"

class EnveJob
   # Class-level
   def self.scripts
      File.expand_path("enveomics-master/Scripts", EnveCollection.home)
   end
   # Instance-level
   attr_accessor :task, :values, :start_time, :end_time, :logfile, :pipe
   def initialize(task, values)
      @task = task
      @values = values
      run!
   end
   def run!
      @logfile = Tempfile.new("enveomics")
      logfile.close
      ObjectSpace.define_finalizer(self, proc{ logfile.unlink })
      @pipe = build_pipe
      pipe.add_log(log_path)
      @start_time = Time.now
      # This seems like the best solution, but it's not supported by
      # JRuby 1.7.x, so it breaks packaging. See #15.
      # @wait_thr = Open3.pipeline_start(*pipe.to_open3_pipeline).last
      @wait_thr = Open3.pipeline_start(cmd).last
      # @wait_thr = spawn(*pipe.to_spawn)
      # @wait_thr = Thread.new { IO.popen(cmd){} }
   end
   def status
      @wait_thr.status
   end
   def alive?
      o = @wait_thr.alive?
      @end_time ||= Time.now unless o
      o
   end
   def cmd
      pipe.to_s
   end
   def log
      File.read(log_path)
   end
   def log_path
      @logfile.path
   end
   def running_time
      end_time - start_time
   end

   private

      def call_task
	 o = EnveTask.class_variable_get(
		  "@@#{task.interpreter.upcase}").shellescape
	 o += " -f" if task.interpreter == "awk"
	 o += " " + File.expand_path(task.task, EnveJob.scripts).shellescape
      end
      
      def build_pipe
	 pipe = EnvePipe.new
	 if values.nil?
	    pipe.append(call_task, false)
	    pipe.append(task.help_arg, false) unless task.help_arg.nil?
	    return pipe
	 end
	 
	 pipe.last += call_task unless task.explicit_task?
	 task.each_option do |i,o|
	    if o.arg == :task
	       pipe.append(call_task, false)
	    elsif o.as_is?
	       if o.opt == ">"
		  pipe.add_ring :stdout
	       elsif o.opt == "2>"
		  pipe.add_ring :stderr
	       elsif o.opt == "%>"
	          pipe.add_ring :stderrout
	       elsif o.opt == "<"
		  pipe.add_ring :stdin
	       else
		  pipe.append(o.opt, false)
	       end
	    else
	       if o.arg!=:nil and (values[i].nil? or values[i]=="")
		  raise "#{o.name} is mandatory." if o.mandatory?
		  next
	       end
	       case o.arg
		  # Flags
		  when :nil
		     pipe.append o.opt if values[i]
		  # Numbers
		  when :integer, :float
		     pipe.append o.opt unless o.opt.nil?
		     v = o.arg==:integer ? values[i].to_i : values[i].to_f
		     pipe.append v.to_s
		  # Strings
		  when :character
		     pipe.append o.opt unless o.opt.nil?
		     pipe.append values[i].to_s[0]
		  else
		     pipe.append o.opt unless o.opt.nil?
		     pipe.append values[i]
	       end
	    end
	 end
	 return pipe
      end
end

class EnvePipe
   # Class-level
   @@RING_SYMBOL = {stderr:"2>", stdout:">", stderrout:"&>", stdin:"<", cmd:"|"}
   @@OPEN3_SYMBOL = {stderr: :err, stdout: :out, stdin: :in}
   # Instance-level
   attr_accessor :pipe, :type
   def initialize
      @pipe = [""]
      @type = [:cmd]
      @reserve = {stderr:false, stdout:false, stdin:false}
   end
   def [](i)	 @pipe[i] ; end
   def []=(i,v)	 @pipe[i] = v ; end
   def first()	 @pipe.first ; end
   def last()	 @pipe.last ; end
   def first=(v) @pipe[0] = v ; end
   def last=(v)	 @pipe[pipe.size-1] = v ; end
   def reserved?(type)
      @reserve[type.to_sym]
   end
   def reserve!(type)
      raise "Slot #{type} was previously reserved." if reserved? type
      @reserve[type.to_sym] = true
   end
   def unreserved
      return :stderrout unless reserved?(:stdout) or reserved?(:stderr)
      return :stderr unless reserved? :stderr
      return :stdout unless reserved? :stdout
      return nil
   end
   def append(v, escape=true)
      self.last += " " unless self.last==""
      self.last += (escape ? v.shellescape : v)
   end
   def add_ring(type=:cmd)
      @pipe << ""
      @type << type
      reserve!(:stderr) if type==:stderr or type==:stderrout
      reserve!(:stdout) if type==:stdout or type==:stderrout
      reserve!(:stdin)  if type==:stdin
   end
   def add_log(path)
      if unreserved.nil?
	 # No slot for log, just make an empty file
	 File.open(path, "w"){}
      else
	 add_ring unreserved
	 append path
      end
   end
   def to_open3_pipeline
      cmds = []
      opts = {}
      pipe.each_index do |i|
	 if type[i]==:cmd
	    cmds << pipe[i]
	 elsif type[i]==:stderrout
	    # For some reason this works from jruby but not from the jar:
	    opts[:err] = `echo #{pipe[i]}`.chomp
	    opts[:out] = `echo #{pipe[i]}`.chomp
	 elsif [:stderr,:stdout,:stdin].include? type[i]
	    opts[@@OPEN3_SYMBOL[type[i]]] = `echo #{pipe[i]}`.chomp
	 else
	    raise "Unsupported type: #{type[i]}."
	 end
      end
      cmds << opts
      cmds
   end
   def to_spawn
      cmds = to_open3_pipeline
      opts = cmds.pop
      [cmds.join(" | "), opts]
   end
   def to_s
      o = ""
      pipe.each_index do |i|
	 o += " " + @@RING_SYMBOL[type[i]] + " " unless i==0
	 o += pipe[i]
      end
      o
   end
end
