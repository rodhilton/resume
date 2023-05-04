require 'rake/clean'
require 'yaml'

task :default => [:all]

TARGET_DIR="docs"

CLEAN.include(TARGET_DIR)

data_files = "resume.yaml,skills.yaml"

public_flags = "-f expand_school -f certifications -f complete_history -f publications"

def private_flags 
  contact = YAML.load_file("contact.yaml")
  email = contact["email"]
  phone = contact["phone"]
  abort("Missing required values in contact.yaml") if email.nil? or phone.nil?
  "-f \"email:#{email}\" -f \"phone:#{phone}\""
end

task :make_target do |t|
  Dir.mkdir(TARGET_DIR) unless File.exists?(TARGET_DIR)
end

file "qr_code_contact.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml,contact.yaml qr_code_contact.txt.erb > qr_code_contact.txt"
  sh "cat qr_code_contact.txt | qrencode -o #{TARGET_DIR}/qr_code_contact.png -t png -m 0 --size=20 --foreground=4786b2"
  rm "qr_code_contact.txt"
end

file "qr_code_url.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml qr_code_url.txt.erb > qr_code_url.txt"
  sh "cat qr_code_url.txt | qrencode -o #{TARGET_DIR}/qr_code_url.png -t png -m 0 --size=20 --foreground=444444"
  rm "qr_code_url.txt"
end

file "profile.png" => [:make_target] do |t|
  sh "cp resources/profile.jpg #{TARGET_DIR}/profile.jpg"
end

task :copy_deps do |t|
  FileUtils.cp_r File.join("latex", "*" ), TARGET_DIR
  FileUtils.cp_r File.join("resources", "*" ), TARGET_DIR
  #FileUtils.cp_r Dir.glob( "*.png" ), TARGET_DIR
  #FileUtils.cp_r Dir.glob( "*.eps" ), TARGET_DIR
end

file "#{TARGET_DIR}/resume_public.tex"  => [:make_target] do |t|
  #sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
  sh "templator/templator -d #{data_files} resume.tex.erb -f color #{public_flags} -f expand_school -f show_projects -f photo:profile > #{TARGET_DIR}/resume_public.tex"
end

file "#{TARGET_DIR}/resume_private.tex"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb -f color #{private_flags} -f expand_coursework -f photo:profile > #{TARGET_DIR}/resume_private.tex"
end

file "#{TARGET_DIR}/resume_public.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.md.erb #{public_flags} > #{TARGET_DIR}/resume_public.md"
end

file "#{TARGET_DIR}/resume_short.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.md.erb > #{TARGET_DIR}/resume_short.md"
end

file "#{TARGET_DIR}/resume.txt" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.txt.erb #{public_flags} > #{TARGET_DIR}/resume.txt"
end

file "#{TARGET_DIR}/resume_public.html"  => [:make_target] do |t|
    sh "templator/templator -d #{data_files} resume.html.erb #{public_flags} > #{TARGET_DIR}/resume_public.html"
end

desc "Make public resume HTML"
task :html_public => "#{TARGET_DIR}/resume_public.html" do |t|
  sh "cp #{TARGET_DIR}/resume_public.html #{TARGET_DIR}/index.html"
end

desc "Make public resume HTML (inlineable)"
task :html_public_inline => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.html.erb #{public_flags} -f inline > #{TARGET_DIR}/resume_public_inline.html"
end

task :latex_public => ["#{TARGET_DIR}/resume_public.tex", :copy_deps, "qr_code_url.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && xelatex resume_public.tex"
  rm "#{TARGET_DIR}/resume_public.tex"
end

task :latex_private => ["#{TARGET_DIR}/resume_private.tex", :copy_deps, "profile.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && xelatex resume_private.tex"
  #rm "#{TARGET_DIR}/resume_private.tex"
  FileUtils.cp_r File.join(TARGET_DIR, "resume_private.pdf"), File.join(TARGET_DIR, "RodHilton_resume.pdf")
end

task :parseable_txt => ["#{TARGET_DIR}/resume.txt", :copy_deps] do |t|
end

desc "Build single-page web site"
task :rodhilton_site => [:make_target] do |t|
  FileUtils.cp_r "rodhilton.com", TARGET_DIR
  FileUtils.mkdir_p File.join(TARGET_DIR, "rodhilton.com", "img")
  FileUtils.mkdir_p File.join(TARGET_DIR, "rodhilton.com", "_includes")
  FileUtils.cp Dir.glob(File.join("resources", "*")), File.join(TARGET_DIR, "rodhilton.com", "img")
  sh "templator/templator -d #{data_files} rodhilton.index.html.erb > #{TARGET_DIR}/rodhilton.com/index.html"
  sh "templator/templator -d #{data_files} rodhilton.com.about.html.erb > #{TARGET_DIR}/rodhilton.com/_includes/about.html"
  sh "templator/templator -d #{data_files} rodhilton.com.experience.html.erb > #{TARGET_DIR}/rodhilton.com/_includes/experience.html"
  sh "templator/templator -d #{data_files} rodhilton.com.education.html.erb > #{TARGET_DIR}/rodhilton.com/_includes/education.html"
  sh "templator/templator -d #{data_files} rodhilton.com.skills.html.erb > #{TARGET_DIR}/rodhilton.com/_includes/skills.html"
  sh "templator/templator -d #{data_files} rodhilton.com.projects.html.erb > #{TARGET_DIR}/rodhilton.com/_includes/projects.html"
end

desc "Make private resume PDF"
task :resume_private => [:latex_private, :parseable_txt]

desc "Make public resume PDF"
task :resume_public => [:latex_public, :html_public, "#{TARGET_DIR}/resume_public.md", "#{TARGET_DIR}/resume_short.md"]

desc "Make all resumes"
task :all => [:resume_public, :resume_private]
