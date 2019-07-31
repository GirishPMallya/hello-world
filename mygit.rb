require 'optparse'
require 'optparse/time'
require 'octokit'
require 'io/console'
require 'logger'

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

   #Handling the Git Configuration 

   parser.on('--config', 'Configure Git') do
        configExist?()
   end

   #Handling the Request Review Command --review
   
   parser.on('-r','--request = reviewer', Array, 'Request review from collaborators') do |reviewer|
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

   #Handling the force command for push and Config

   parser.on('-f', '--force', 'Force Push') do |force|
        $force='True'
   end


options[:files] += ARGV
options[:repoandbranch] += ARGV
options[:reviewers] += ARGV

$LOG = Logger.new('log_file.log', 'monthly')

def configExist?()
         $LOG.debug("<MyGit> : Checking if Config Exists")
         repo = getreponame()
         Dir.chdir "#{repo}/.#{repo}"
         if File.file?('gitconfig.txt')
                $LOG.debug("<MyGit> : <ConfigExist?> : The config file exists")
                Dir.chdir('../..')
                if ARGV.include?('-f')
                        $LOG.debug("<MyGit> : <ConfigExist?> : Forcefully creating a new config")
                        ConfigGit()
                        return                        
                end
                puts "<MyGit> : Config Exists already \n use -f tag to force a new config"
                $LOG.debug("<MyGit> : <ConfigExist?> : Config Already Exists!")
         else
                $LOG.debug("<MyGit> : <ConfigExist?> : Calling the ConfigGit function to configure the user's git")
                Dir.chdir('../..')
                ConfigGit()
        
         end

         
end


def ReturnGitCredentials()
        $LOG.debug("<MyGit> <ReturnGitCredentials> : Checking if credentials are stored")
        repo=getreponame()
        Dir.chdir(repo)
        gitconfig = readhidden(repo,"gitconfig.txt")
        gitconfig = gitconfig.split("\n")

        return gitconfig
end


def ConfigGit()
        
        $LOG.debug("<MyGit> <ConfigGit> : Asking for the user`s git credentials through console")
        print "Enter your GitHub username: "
        username = STDIN.gets.chomp
        print "Enter your GitHub Passowrd: "
        password = STDIN.noecho(&:gets).chomp
        puts "\n"
        gitconf = username+"\n"+password
        repo = getreponame()
        Dir.chdir(repo)
        $LOG.debug("<MyGit> <ConfigGit> : Writing to gitconfig file")
        writetofile("gitconfig.txt",gitconf,repo)
        $LOG.debug("<MyGit> <ConfigGit> : Git credentials have been configured")
        puts "<MyGit> : Git Credentials have been successfully configured"
end


def octoKitInit()
        $LOG.debug("<MyGit> <octoKitInit>  : Initializing Octokit API for git")
        gitconfig = ReturnGitCredentials()
        login = gitconfig[0]
        password = gitconfig[1]
        client = Octokit::Client.new(:login => login , :password => password)
        $LOG.debug("<MyGit> <octoKitInit> : Successfully logged into Octokit")
        return client
end

def GitExist?
        $LOG.debug("<MyGit> : <GitExist?> : Checking if the user has git installed")
        git_path = `which git`
        if git_path.length > 0
                $LOG.debug("<MyGit> : <GitExist?> : Git exists")
                return true

        else
                $LOG.debug("<MyGit> : <GitExist?> : Git isnt installed, requesting the user to install git")
                puts "<MyGit> : <Error> : git isn`t installed on your system, kindly install and run the app again!"
                return false
        end
        
end     


def getreponame
        $LOG.debug("<MyGit> : <getreponame> : Asking for reponame")
        repo = File.open('repo.txt', 'r').read
        repo = repo.split('/')[1]
        return repo

end

def mygit_create(repoandbranch)
        $LOG.debug("<MyGit> <mygit_create> : mygit_create called with repo: #{repoandbranch[1]} and branch: #{repoandbranch[2]}")
        $LOG.debug("<MyGit> <mygit_create> : Checking for git exists : #{GitExist?()}")
        if !GitExist?()
                $LOG.debug("<MyGit> <mygit_create> : Exiting because git doesn`t exist")
                exit
        end
        repo = repoandbranch[1]
        branch =  repoandbranch[2]
        $LOG.debug("<MyGit> <mygit_create> : Starting to clone the repo #{repo}")
        system "git clone #{repo}"
        puts "<MyGit> : Successfully Cloned #{repo}"        
        $LOG.debug("<MyGit> <mygit_create> : Successfully cloned #{repo}")
        #Get the last modified folder (which will be the cloned repo) so that
        #we can cd into it
       
        lastmod = getlastmodified()
        $LOG.debug("<MyGit> <mygit_create> : last modified directory : #{lastmod}")
       
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
        $LOG.debug("<MyGit> <mygit_create> : Created the Hidden Directory to store data")
        system "git init"
        system "git pull"

        if !(branch==repo)
                system "git branch #{branch}"
                system "git checkout #{branch}"
                writetofile("Direx.txt",branch,repo)
                repodirex= "#{pw}"+"/repo.txt"
                $LOG.debug("<MyGit> <mygit_create> : Writing #{repolink} to the files")
                writetofile(repodirex,repolink,repo)
                writetofile("repo.txt",repolink,repo)                                                           
                puts "<MyGit> : Successfully created branch :  #{branch}"
                $LOG.debug("<MyGit> <mygit_create> : Successfully executed the create command!")
        end


end
def writetofile(fname,content,repo)
        Dir.chdir ".#{repo}" do
        File.open(fname, 'w') {|file| file.write(content)}
        $LOG.debug("<MyGit> <writetofile> : Successfully wrote #{content} to #{fname}")
        end
end

def getlastmodified()
        $LOG.debug("<MyGit> <getlastmodified> : getting the last modified file")
        lastmod= `ls -td -- */ | head -n 1 | cut -d'/' -f1`
        lastmod =lastmod.chomp
        return lastmod
end

def Base?(repo)
        Dir.chdir "#{repo}/.#{repo}"
        if File.file?('Base.txt')
                $LOG.debug("<MyGit> <Base?> : Base File exists")
                base = File.open('Base.txt').read
        end
        Dir.chdir "../.."
        if base.nil?
                $LOG.debug("<MyGit> <Base?> : Base file is empty")
                return false
        else
                $LOG.debug("<MyGit> <Base?> : Base branch is #{base}")
                return true
        end
end


def readhidden(repo,file)

        Dir.chdir ".#{repo}"
        if !File.exist?(file)
                $LOG.debug("<MyGit> <readhidden> : #{file} doesn't exist")
                puts " <MyGit> : Error : File doesn`t exist"
                exit
        end
        data = File.open(file, 'r').read
        Dir.chdir ".."
        $LOG.debug("Read data #{data} from #{file}")
        return data


end


def mygit_prepare(base)
        
        repo = getreponame()
        if base.nil? and !(Base?(repo))
                $LOG.debug("<MyGit> <mygit_prepare> : Base Branch is not specified")
                puts "Base branch not specified!"
                exit
        end
        Dir.chdir(repo)
        if base.nil?
        $LOG.debug("<MyGit> <mygit_prepare> : Reading base from file as it is not provided in function parameter")
        base = readhidden(repo, "Base.txt")
        end

        writetofile("Base.txt",base,repo)
        
        $LOG.debug("<MyGit> <mygit_prepare> : Calling rebase")
        system "git rebase #{base}"
        $LOG.debug("<MyGit> <mygit_prepare> : Rebase ended")
        directory = readhidden(repo,"Direx.txt")

        if $force == 'True'
                system "git push -f -u origin #{directory}"
        else
                system "git push -u origin #{directory}"
        end
        $LOG.debug("<MyGit> <mygit_prepare> : git pushed #{directory}")
end

def mygit_request(reviewers)
        $LOG.debug("Request Called")
        $LOG.debug("<MYGIT> <mygit_request>module : Check if git exists? : #{GitExist?()}")
        reviewers.shift
        repo_directory = File.open("repo.txt")
        repo_directory = repo_directory.read
        repo = getreponame()
        
        Dir.chdir(repo)
        
        base_branch = readhidden(repo,"Base.txt")       

        working_branch = readhidden(repo,"Direx.txt")

	Dir.chdir('..')
        client = octoKitInit()

        create_pull = client.create_pull_request(repo_directory,base_branch, working_branch , "From Girish's App", "Pull Request body")
        
        reqreview=client.request_pull_request_review(repo_directory, create_pull.number , reviewers: reviewers)
        
        reviewers.each do |reviewer|        
                puts "<MyGit> : Review requested by #{reviewer}"
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
                 puts "<MyGit> : Review not done yet"
                 exit 
        else
                review_ix= review_status.length - 1
                
                status=client.pull_request_review(repo_directory, pullreq, review_status[review_ix].id)

                                                                                                                
                puts status.state

        end

                
        if status.state == 'APPROVED' 
                puts "<MyGit> : your review is approved"
                system "git add ."
                system "git commit -m 'from Girish's App'"
                system "git merge --squash #{base}"

        end

end


end.parse!
