require 'optparse'
require 'optparse/time'
require 'octokit'

$force = 'False'
options ={
:files => [],
:repoandbranch => [],
:force => 'False',
:reviewers => []
}
OptionParser.new do |parser|
   #Handling the -create Command

   parser.on('-c', '--create=repo branch',Array, 'Create a Repo and Branch') do |create|
        options[:repoandbranch] += create  
        mygit_create(options[:repoandbranch])
   end
   #Handling the Check Status --status command
   parser.on('-s','--status', 'Check Status of recent pull request and review request') do |status|
        mygit_status()
   end

   #Handling the Request Review Command --review
   parser.on('-r','--request = reviewer', Array, 'Request review from collaborators') do |reviewer|
           #options[:reviewers] += reviewer
           mygit_request(options[:reviewers])
   end

   #Handling the prepare command
   parser.on('-p', '--prepare [master]', String , 'Rebase against Base') do |base|
        options[:base]=base
        if ARGV.include?('-f')
                $force = 'True'
        end
         mygit_prepare(base)
          end

   parser.on('-f', '--force', 'Force Push') do |force|
        $force='True'
   end


options[:files] += ARGV
options[:repoandbranch] += ARGV
options[:reviewers] += ARGV

def octoKitInit()
client = Octokit::Client.new(:login => 'GirishPMallya', :password => 'testapipwtesttest')
return client
end

def GitExist?
        git_path = `which git`
        if git_path.length > 0
                return true

        else
                puts "git isn`t installed on your system, kindly install and run the app again!"
                return false
        end
        
end     


def getreponame
        repo = File.open('repo.txt', 'r').read
        repo = repo.split('/')[1]
        return repo

end

def mygit_create(repoandbranch)

        if !GitExist?()
                exit
        end
        repo = repoandbranch[1]
        branch =  repoandbranch[2]
        system "git clone #{repo}"
        
        #Get the last modified folder (which will be the cloned repo) so that
        #we can cd into it
       
        lastmod = getlastmodified()

       
        #cd into it
       
        pw = `pwd`
        pw=pw.chomp
                                        
        Dir.chdir "#{lastmod}"
        username = repo.split('/')[3]
        repo=(repo.split('/')[4]).split('.')[0]
        puts repo
        repolink  = "#{username}"+"/"+"#{lastmod}"
        Dir.mkdir(lastmod)
        `mv #{lastmod} .#{lastmod}`

        system "git init"
        system "git pull"

        if !(branch==repo)
                system "git branch #{branch}"
                system "git checkout #{branch}"
                writetofile("Direx.txt",branch,repo)
                repodirex= "#{pw}"+"/repo.txt"
                puts repodirex
                writetofile(repodirex,repolink,repo)
                writetofile("repo.txt",repolink,repo)                                                           
                puts "Creating branch #{branch}"
        end


end
def writetofile(fname,content,repo)
        Dir.chdir ".#{repo}" do
        File.open(fname, 'w') {|file| file.write(content)}
        end
end

def getlastmodified()
        lastmod= `ls -td -- */ | head -n 1 | cut -d'/' -f1`
        lastmod =lastmod.chomp
        return lastmod
end

def Base?(repo)
        Dir.chdir "#{repo}/.#{repo}"
        if File.file?('Base.txt')
                base = File.open('Base.txt').read
        end
        Dir.chdir "../.."
        if base.nil?
                return false
        else
                return true
        end
end


def readhidden(repo,file)

        Dir.chdir ".#{repo}"
        if !File.exist?(file)
                puts "File doesn`t exit"
                exit
        end
        data = File.open(file, 'r').read
        Dir.chdir ".."
        return data


end


def mygit_prepare(base)
        
        repo = getreponame()
        if base.nil? and !(Base?(repo))
                puts "Base branch not specified!"
                exit
        end
        Dir.chdir(repo)
        if base.nil?
        base = readhidden(repo, "Base.txt")
        end

        writetofile("Base.txt",base,repo)

        system "git rebase #{base}"

        directory = readhidden(repo,"Direx.txt")
        puts directory

        if $force == 'True'
                system "git push -f -u origin #{directory}"
        else
                system "git push -u origin #{directory}"
        end
end

def mygit_request(reviewers)
        reviewers.shift
        repo_directory = File.open("repo.txt")
        repo_directory = repo_directory.read
        repo = getreponame()
        
        Dir.chdir(repo)
        
        base_branch = readhidden(repo,"Base.txt")       

        working_branch = readhidden(repo,"Direx.txt")
        
        client = octoKitInit()
        create_pull = client.create_pull_request(repo_directory,base_branch, working_branch , "From Girish's App", "Pull Request body")
        
        reqreview=client.request_pull_request_review(repo_directory, create_pull.number , reviewers: reviewers)
        
        reviewers.each do |reviewer|        
                puts "Review requested by #{reviewer}"
        end


        comparison_branches = client.compare(repo_directory, base_branch ,working_branch , options = {})
        comparison_json = Hash.new
        counter=0
        comparison_branches.files.each do |file|
                array_files=[]  

                file.each do |f|
                        array_files.push(f)
        
                end

                comparison_json[counter] = array_files
                        counter=counter+1
        end
        File.open("comparison_result.json","w") do |f|
                f.write(comparison_json.to_json)
        end

        writetofile("pullreq.txt", create_pull.number, repo)
        writetofile("reviewreq.txt", reqreview.id , repo)                        
  
                                
end

def mygit_status()
        client = octoKitInit()
        repo = getreponame()
        repo_directory = File.open("repo.txt").read
        Dir.chdir(repo)
        pullreq=readhidden(repo,"pullreq.txt")
        reviewreq = readhidden(repo,"reviewreq.txt")
        base = readhidden(repo,"Base.txt")

        review_status=client.pull_request_reviews(repo_directory, pullreq)
                        
        if review_status.empty?
                 puts "Review not done yet"
                 exit 
        else
                review_ix= review_status.length - 1
                
                status=client.pull_request_review(repo_directory, pullreq, review_status[review_ix].id)

                                                                                                                
                puts status.state

        end

                
        if status.state == 'APPROVED' 
                puts "your review is approved"
                system "git add ."
                system "git commit -m 'from Girish's App'"
                system "git merge --squash #{base}"

        end

end


end.parse!
