#
# @package enveomics
# @author  Luis M. Rodriguez-R <lmrodriguezr at gmail dot com>
# @license artistic license 2.0
#

require "tempfile"
require "open3"
require "enve-collection"
if $IS_CLI
   require "shoes"
   require "shoes/swt"
   Shoes::Swt.initialize_backend
end

class EnveGUI < Shoes
   url "/", :home
   url "/index", :index
   url "/about", :about
   url "/update", :update
   url "/subcat-(.*--.*)", :subcat
   url "/script-(.*)", :script
   $enve_path  = File.expand_path("../../Scripts", File.dirname(__FILE__))
   $img_path   = File.expand_path("../img", File.dirname(__FILE__))
   $enve_jobs  = {}
   $citation   = [
      "Rodriguez-R and Konstantinidis. In preparation. The enveomics ",
      "collection: a toolbox for specialized analyses in genomics and ",
      "metagenomics."].join
   $gui_citation = [
      "The Graphical User Interface was developed on Shoes4 by ",
      "Luis M. Rodriguez-R [lmrodriguezr@gmail.com]. ",
      "Icons by Yu Luck from the Noun Project ",
      "[https://thenounproject.com/yuluck/uploads]."].join

   def self.init (&block)
      Shoes.app(title: "Enveomics | Everyday bioinformatics",
	 width: 750, height: 500, &block)
   end
   
   # =====================[ View : Windows ]
   # Main window
   def home
      header "/"
      stack(margin:[40,0,40,0]) do
	 title "Welcome to the Enveomics collection!", align:"center"
	 $home_info = para "Retrieving enveomics...", align:"center"
	 $manif_path = EnveCollection.manif
	 if $manif_path.nil?
	    zip_target = File.expand_path("master.zip", EnveCollection.home)
	    download EnveCollection.master_url,
	       save: zip_target,
	       finish: proc { |d|
		  $home_info.text = "Unzipping..."
		  # ToDo: Improve the next line!
		  system("cd #{EnveCollection.home.shellescape} " +
		     "&& unzip master.zip")
		  File.unlink(zip_target)
		  $manif_path = EnveCollection.manif
		  show_home
	       }
	 else
	    show_home
	 end
      end
      footer
   end
   
   # Index of all tasks
   def index
      header "/index"
      stack(margin:[40,0,40,0]) do
	 stack do
	    $collection.each_category do |cat_name, cat_set|
	       stack(margin: 20) do
		  subtitle cat_name
		  cat_set.each do |subcat_name, subcat_set|
		     stack(margin: 10) do
			para strong(subcat_name)
			show_subcat(subcat_set)
		     end # stack (subcategory)
		  end # each subcategory
	       end # stack (category)
	    end # each category
	 end # stack (collection)
      end # stack (main)
      footer
   end

   # Scripts per subcategory
   def subcat(subcatpath)
      (cat,subcat) = subcatpath.split("--")
      header
      stack(margin:[40,0,40,0]) do
	 title cat, " / ", subcat
	 cat_set = $collection.category(cat)
	 subcat_set = cat_set[subcat.to_sym]
	 show_subcat(subcat_set)
      end
      footer
   end

   # About enveomics
   def about
      header "/about"
      stack(margin:[40,0,40,0]) do
	 title "About the enveomics collection", align:"center"
	 para ""
	 subtitle "Citation"
	 edit_box $citation, width:1.0, height:60, state: "readonly"
	 para ""
	 subtitle "GUI Resources"
	 edit_box $gui_citation, width:1.0, height:60, state: "readonly"
      end
      footer
   end

   # Update enveomics
   def update
      FileUtils.rm_rf(File.dirname($manif_path))
      $manif_path = nil
      $collection = nil
      visit "/"
   end

   # Script query
   def script(task)
      header
      stack(margin:[40,0,40,0]) do
	 @t = $collection.task(task)
	 title @t.task
	 para @t.description
	 unless @t.ready?
	    para ""
	    stack(margin:[50,0,50,0]) do
	       background "#fdd"..."#f99"
	       border "#300"
	       stack(margin:[20,0,20,0]) do
		  para ""
		  para strong("This script cannot be used due to unmet" +
		     " requirements:")
		  @t.unmet.each do |r|
		     para r.description, margin:[10,0,10,0]
		  end
		  para ""
	       end
	    end
	 end
	 para "", margin:10
	 @opt_value = []
	 @opt_elem  = []
	 @t.each_option do |opt_i,opt|
	    next if opt.hidden?
	    stack(margin:[10,0,10,0]) do
	       subtitle opt.name
	       para opt.description if opt.description and opt.arg!=:nil
	       case opt.arg
		  when :nil
		     flow do
			@opt_elem[opt_i] = check
			para opt.description if opt.description
		     end
		  when :in_file,:out_file,:in_dir,:out_dir
		     flow do
			b_t = {in_file: "Open file", out_file: "Save as",
			   in_dir: "Open folder", out_dir: "Save folder as"}
			button(b_t[opt.arg]) do
			   @file = opt.arg==:in_file ? Shoes.ask_open_file :
			      opt.arg==:out_file ? Shoes.ask_save_file :
			      opt.arg==:in_dir ? Shoes.ask_open_folder :
			      Shoes.ask_save_folder
			   unless @file.nil?
			      @opt_value[opt_i] = @file
			      @opt_elem[opt_i].text = @opt_value[opt_i]
			   end
			end
			@opt_elem[opt_i] = edit_line ""
		     end
		  when :select
		     @opt_elem[opt_i] = list_box items: opt.values
		  when :string, :integer, :float
		     @opt_elem[opt_i] = edit_line opt.default
	       end
	       inscription opt.note if opt.note
	       opt.source_urls.each{ |url| para link(url){ open_url(url) } }
	    end # stack (option)
	    para "", margin:10
	 end # each option
	 para strong("* Required"), margin:[10,0,10,0]
	 para ""
	 flow do
	    button("Execute") do
	       @values = []
	       @t.each_option do |opt_i, opt|
		  e = @opt_elem[opt_i]
		  @values[opt_i] = e.nil? ? nil :
		     e.is_a?(Check) ? e.checked? : e.text
	       end
	       launch_analysis(@t, @values)
	    end
	    button("Reset defaults"){ visit "/script-#{task}" }
	    unless @t.hash[:help_arg].nil?
	       button("Embedded help") do
		  launch_analysis(@t, nil)
	       end
	    end
	 end
      end # stack (task)
      footer
   end

   # =====================[ View : Elements ]
   def header(in_page="")
      self.scroll_top = 0
      background pattern(img_path("bg1.png"))
      #@the_background = background "#B2E5F4" .. "#F1E1F4"
      #@the_background_seeds = [250,250,250]
      #animate(4) do |frame|
	 #-- Method 1: Smooth change
	 #smidge = (16*(0.5+Math.sin(frame.to_f/10)/2)).to_i
	 #@the_background.fill = rgb(239+smidge, 255-smidge, 239+smidge)
	 #-- Method 2: Beware the headache!
	 #@the_background_seeds.map! do |v|
	 #   [[255,v-2+rand(5)].min,128].max
	 #end
	 #@the_background.fill = rgb(*@the_background_seeds)
      #end
      stack do
	 background rgb(178,229,244,1.0)
	 flow(width:1.0) do
	    stack(width:40){}
	    menu = [
	       ["Home","/","noun_208357_cc.png"],
	       ["All tasks","/index","noun_208394_cc.png"],
	       ["Update","/update","noun_229107_cc.png"],
	       ["Website","http://enve-omics.ce.gatech.edu/",
		  "noun_208472_cc.png"],
	       ["About","/about","noun_229118_cc.png"]
	    ]
	    menu.each do |i|
	       stack(width:50) do
		  background rgb(158,209,224) if i[1]==in_page
		  image img_path(i[2]),
		     width:50, height:50, margin:2
		  inscription i[0], align:"center"
	       end.click { (i[1]=~/^https?:/) ? open_url(i[1]) : visit(i[1]) }
	       stack(width:20){}
	    end
	 end
	 stack(height:5, width:1.0){}
	 stack(height:2, width:1.0) { background black }
      end
      stack(height:20, width:1.0){}
   end

   def footer
      para "", margin:50
   end
   
   # =====================[ Controller : Tasks / Helpers ]
   def launch_analysis(t, values)
      begin
	 log = Tempfile.new("enveomics")
	 log.close
	 cmd = t.build_cmd(values, log)
	 window(title: "Running #{t.task}", width: 750, height: 512) do
	    background "#B2E5F4" .. "#F1E1F4"
	    @cmd = cmd
	    @log = log
	    stack(margin:30, width:1.0) do
	       subtitle t.task
	       para strong("Command:")
	       edit_box @cmd, width:1.0, height:40, state:"readonly"
	       para ""
	       @start_time = Time.now
	       @wait_thr = Open3.pipeline_start(@cmd).first
	       para strong("Start time: "), @start_time.ctime
	       para strong("Log: "), @log.path
	       @running = edit_box "", state:"readonly",
					  width:1.0, height: 275
	       animate(4) do |frame|
		  unless @running.nil?
		     @running.text = File.read(@log.path)
		     if @wait_thr.alive?
			@running.text += "\n#{@wait_thr.status}"+("."*(frame%4))
		     else
			@log.unlink
			para ""
			para strong("Running time: "),Time.now-@start_time,"s."
			@running = nil
		     end
		  end
	       end
	    end
	 end
      rescue => e
	 Shoes.alert "#{e}\n\n#{e.backtrace.first}"
      end
   end
   
   def show_home
      $home_info.text = "Loading collection..."
      $collection ||= EnveCollection.new($manif_path)
      $home_info.text = ""
      
      para ""
      flow(width:1.0) do
	 # (Sub)categories
	 stack(width:0.38) do
	    $collection.each_category do |cat, cat_set|
	       subtitle cat, align:"right"
	       inscription ""
	       cat_set.each do |subcat, subcat_set|
		  tagline link(subcat, click:"/subcat-#{cat}--#{subcat}"),
		     weight:"bold", align:"right"
		  para "#{subcat_set.count} tasks", align:"right"
		  inscription ""
	       end # each subcategory
	       para ""
	    end # each category
	 end # stack (collection)
	 # Separator
	 stack(width:0.04){}
	 # Sidebar for fun stuff
	 stack(width:0.58) do
	    subtitle "The most popular"
	    inscription ""
	    %w(ani.rb aai.rb FastQ.split.pl Taxonomy.silva2ncbi.rb
		     AlphaDiversity.pl).each do |t|
	       para strong(link(t, click:"/script-#{t}"), ": "),
		  $collection.task(t).description
	       inscription ""
	    end
	    para ""
	    subtitle "Some random suggestions"
	    inscription ""
	    $collection.tasks.sample(5).each do |t|
	       para strong(link(t.task, click:"/script-#{t.task}"), ": "),
		  t.description
	       inscription ""
	    end
	    para ""
	    subtitle "Citation"
	    inscription ""
	    para $citation
	    para ""
	    inscription ""
	    subtitle "GUI Resources"
	    inscription ""
	    para $gui_citation
	    para ""
	    inscription ""
	 end
      end # flow (the whole ordeal)
   end
   
   def show_subcat(subcat_set)
      subcat_set.each do |t_name|
	 t = $collection.task(t_name)
	 if t.nil?
	    para t_name, stroke: "#777", margin: 5
	 else
	    para link(t.task, click: "/script-#{t.task}"),
	       ": ", t.description, margin: 5
	 end
      end # each task
   end

   def img_path(img)
      # Easy peasy for normal files
      o = File.expand_path(img, $img_path)
      return o if __FILE__ !~ /\.jar!\//
      # Juggling around packages:
      h = File.expand_path(img, EnveCollection.home)
      FileUtils.copy(o, h) unless File.exist? h
      h
   end

   # Taken from the code of The Shoes Manual (shoes 3.2):
   def open_url(url)
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
	 system("start #{url}")
      elsif RbConfig::CONFIG['host_os'] =~ /darwin/
	 system("open #{url}")
      elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
	 system("xdg-open #{url}")
      end
   end
end
