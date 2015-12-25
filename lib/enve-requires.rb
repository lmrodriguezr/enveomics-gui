
class EnveRequires
   attr_accessor :hash, :test, :description, :source_url
   attr_accessor :interpreter, :ruby_gem, :perl_lib
   def initialize(o)
      @hash = o
      @hash.each{ |k,v| instance_variable_set("@#{k}", v) }
      
      # Empty requirements are not allowed
      raise "Empty requirement." if
	 %w(test description interpreter ruby_gem perl_lib).map do |k|
	    hash[k.to_sym].nil?
	 end.all?
      
      # Presets for known requirements
      set_by_ruby_gem unless ruby_gem.nil?
      set_by_perl_lib unless perl_lib.nil?
      set_by_interpreter unless interpreter.nil?
      description ||= test
   end
   def pass?
      return true if hash[:test].nil?
      !!system(hash[:test])
   end

   private
      
      def set_by_ruby_gem
         test ||= "#{EnveTask.RUBY} -r #{ruby_gem.shellescape} -e ''"
	 description ||= "Ruby gem #{ruby_gem}"
	 source_url ||= "https://rubygems.org/gems/#{ruby_gem}"
      end

      def set_by_perl_lib
         test ||= "#{EnveTask.PERL} -M#{perl_lib.shellescape} -e ''"
	 description ||= "Perl library #{perl_lib}"
	 source_url ||= "http://search.cpan.org/search?query=#{perl_lib}"
      end
      def set_by_interpreter
	 case interpreter.to_s
	    when "ruby"
	       description ||= "Ruby >= 2.0"
	       test ||= "#{EnveTask.RUBY} -e '{a:1}'" # Illegal before 2.0
	       source_url ||= "https://www.ruby-lang.org/"
	    when "perl"
	       description ||= "Perl"
	       test ||= "#{EnveTask.PERL} --version"
	       source_url ||= "https://www.perl.org/get.html"
	    when "Rscript"
	       description ||= "R"
	       test ||= "#{EnveTask.RSCRIPT} --version"
	       source_url ||= "https://www.r-project.org/"
	    when "awk"
	       description ||= "GNU Awk"
	       test ||= "#{EnveTask.AWK} --version"
	       if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
		  source_url ||= "http://gnuwin32.sourceforge.net/packages/" +
				 "gawk.htm"
	       else
		  source_url ||= "http://www.gnu.org/software/gawk/gawk.html"
	       end
	    when "bash"
	       description ||= "GNU Bash"
	       test ||= "#{EnveTask.BASH} --version"
	       if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
		  source_url ||= "http://win-bash.sourceforge.net/"
	       else
		  source_url ||= "https://www.gnu.org/software/bash/"
	       end
	    else
	       raise "Unsupported interpreter: #{interpreter}."
	 end
      end
end
