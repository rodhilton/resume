require 'rake/clean'
require 'yaml'

CLEAN.include("*.html", "*.tex", "*.log", "*.pdf")

data_files = "resume.yaml,skills.yaml"

file "resume_public.tex" do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb -f expand_school > resume_public.tex"
end

task :latex_public => ["resume_public.tex"] do |t|
  sh "pdflatex resume_public.tex"
  rm "resume_public.tex"
end
  
file "resume_private.tex" do |t|
  contact = YAML.load_file("contact.yaml")
  email = contact["email"]
  phone = contact["phone"]
  abort("Missing required values in contact.yaml") if email.nil? or phone.nil?
  sh "templator/templator -d #{data_files} resume.tex.erb -f expand_school -f private -f \"email:#{email}\" -f \"phone:#{phone}\" > resume_private.tex"
end

task :latex_private => ["resume_private.tex"] do |t|
  sh "pdflatex resume_private.tex"
  rm "resume_private.tex"
end
  
task :latex => [:latex_public, :latex_private]

file "resume_public.html" do |t|
    sh "templator/templator -d #{data_files} resume.html.erb -f expand_school > resume_public.html"
end

task :resume_public => ["resume_public.html"]

task :upload_resume => [:resume_public, :latex_public] do |t|
  pub = YAML.load_file("public.yaml")
  host = pub["host"]
  path = pub["path"]
  abort("Missing required values in public.yaml") if host.nil? or path.nil?
  sh "scp -P 7822 resume_public.html resume_public.pdf #{host}:#{path}"
end
