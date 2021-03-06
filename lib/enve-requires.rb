
class EnveRequires
   attr_accessor :hash, :test, :description, :source_url, :solution
   attr_accessor :interpreter, :ruby_gem, :perl_lib, :r_package
   def initialize(o)
      @hash = o
      @hash.each{ |k,v| instance_variable_set("@#{k}", v) }
      
      # Empty requirements are not allowed
      raise "Empty requirement." if
	 %w(test description interpreter ruby_gem perl_lib r_package).map do |k|
	    hash[k.to_sym].nil?
	 end.all?
      
      # Presets for known requirements
      set_by_ruby_gem unless ruby_gem.nil?
      set_by_perl_lib unless perl_lib.nil?
      set_by_r_package unless r_package.nil?
      set_by_interpreter unless interpreter.nil?
      self.description ||= test
   end
   
   def pass?
      return true if test.nil?
      EnveCollection.sysrun(test)
   end

   def resolve
      return false if solution.nil?
      EnveCollection.sysrun(solution)
   end

   private
      
      def set_by_ruby_gem
         self.test ||= "#{EnveTask.RUBY} -r #{ruby_gem.shellescape} -e ''"
	 self.description ||= "Ruby gem #{ruby_gem}"
	 self.source_url ||= "https://rubygems.org/gems/#{ruby_gem}"
	 self.solution ||= "gem install --user-install #{ruby_gem}"
      end

      def set_by_perl_lib
         self.test ||= "#{EnveTask.PERL} -M#{perl_lib.shellescape} -e ''"
	 self.description ||= "Perl library #{perl_lib}"
	 self.source_url ||= "http://search.cpan.org/search?query=#{perl_lib}"
      end

      def set_by_r_package
	 self.test ||= "#{EnveTask.RSCRIPT} -e 'library(#{r_package})'"
	 self.description ||= "R package #{r_package}"
	 self.source_url ||= "https://cran.r-project.org/package=#{r_package}"
	 self.solution ||= "echo 'install.packages(\"#{r_package}\", " +
	    "repos=\"http://cran.r-project.org\")' | R --vanilla"
      end

      def set_by_interpreter
	 case interpreter.to_s
	    when "ruby"
	       self.description ||= "Ruby >= 2.0"
	       # Instead of explicitly testing for the version, I'm passing a
	       # hash with a syntax that was illegal before 2.0
	       self.test ||= "#{EnveTask.RUBY} -e '{a:1}'"
	       self.source_url ||= "https://www.ruby-lang.org/"
	    when "perl"
	       self.description ||= "Perl"
	       self.test ||= "#{EnveTask.PERL} --version"
	       self.source_url ||= "https://www.perl.org/get.html"
	    when "Rscript"
	       self.description ||= "R"
	       self.test ||= "#{EnveTask.RSCRIPT} --version"
	       self.source_url ||= "https://www.r-project.org/"
	    when "awk"
	       self.description ||= "GNU Awk"
	       # mawk doesn't support --version, and
	       # gawk doesn't support -W version, hence the quirky test
	       self.test ||= "#{EnveTask.AWK} 'BEGIN{exit}'"
	       if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
		  self.source_url ||= "http://gnuwin32.sourceforge.net" +
				    "/packages/gawk.htm"
	       else
		  self.source_url ||= "http://www.gnu.org/software/gawk/"
	       end
	    when "bash"
	       self.description ||= "GNU Bash"
	       self.test ||= "#{EnveTask.BASH} --version"
	       if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
		  self.source_url ||= "http://win-bash.sourceforge.net/"
	       else
		  self.source_url ||= "https://www.gnu.org/software/bash/"
	       end
	    else
	       raise "Unsupported interpreter: #{interpreter}."
	 end
      end
end
