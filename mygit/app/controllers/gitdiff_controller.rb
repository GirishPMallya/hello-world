

require 'open-uri'
class GitdiffController < ApplicationController

	def index
		@filename = 'Hello'			
		@web_contents = open('https://raw.githubusercontent.com/GirishPMallya/upgraded-octo-guide/master/calc.py')
	end
	
	def showdiff
	
		@web_contents = open('https://raw.githubusercontent.com/GirishPMallya/upgraded-octo-guide/master/calc.py')
		@filename = params[:myfile]


	if params[:file].nil?
		file = File.open("/home/girish/bin/hello-world/temp.json").read
	else
		file = params[:file].read
	end
          @data = JSON.parse(file)
          @keys =[]
          @vals =[]
          ctr=0;


        @processed_json = Hash.new
        @data.each do |k,v|
                ctr=0
                eachfile = Hash.new
                v.each do |w|
                         eachfile[w[0]]=w[1]
                end
                puts eachfile['filename']
                @processed_json[eachfile['filename']] = eachfile
        end

        File.open("processedjson.json","w") do |f|
                f.write(@processed_json.to_json)
        end

         # @keys.each do |k| puts k end




	end

	def import
	  file = params[:file].read
	  @data = JSON.parse(file)
	  @keys =[]
	  @vals =[]
	  ctr=0;
	  

        @processed_json = Hash.new
	@data.each do |k,v|
        	ctr=0
        	eachfile = Hash.new
        	v.each do |w|
               		 eachfile[w[0]]=w[1]
        	end
                puts eachfile['filename']
        	@processed_json[eachfile['filename']] = eachfile
	end

	File.open("processedjson.json","w") do |f|
  		f.write(@processed_json.to_json)
	end

	 # @keys.each do |k| puts k end
  
		  

	
end

	def upload

	end

	
	def test
	end


end
