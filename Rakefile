require 'rake/clean'
require 'yaml'

task :default => [:all]

TARGET_DIR="out"

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
  sh "cat qr_code_contact.txt | qrencode -o out/qr_code_contact.png -t png -m 0 --size=20 --foreground=4786b2"
  rm "qr_code_contact.txt"
end

file "qr_code_contact_bw.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml,contact.yaml qr_code_contact.txt.erb > qr_code_contact.txt"
  sh "cat qr_code_contact.txt | qrencode -o out/qr_code_contact_bw.png -t png -m 0 --size=20 --foreground=000000"
  rm "qr_code_contact.txt"
end

file "qr_code_url.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml qr_code_url.txt.erb > qr_code_url.txt"
  sh "cat qr_code_url.txt | qrencode -o out/qr_code_url.png -t png -m 0 --size=20 --foreground=444444"
  rm "qr_code_url.txt"
end

task :copy_deps do |t|
  FileUtils.cp_r Dir.glob( File.join("latex", "*" ) ), TARGET_DIR
  #FileUtils.cp_r Dir.glob( "*.png" ), TARGET_DIR
  #FileUtils.cp_r Dir.glob( "*.eps" ), TARGET_DIR
end

file "#{TARGET_DIR}/resume_public.tex"  => [:make_target] do |t|
  #sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
  sh "templator/templator -d #{data_files} resume.tex.erb -f color #{public_flags} -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
end

file "#{TARGET_DIR}/resume_full.tex"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb -f color #{public_flags} #{private_flags} -f photo:qr_code_contact > #{TARGET_DIR}/resume_full.tex"
end

file "#{TARGET_DIR}/resume_private.tex"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb -f color #{private_flags} -f photo:qr_code_contact > #{TARGET_DIR}/resume_private.tex"
end

file "#{TARGET_DIR}/resume_private_bw.tex"  => [:make_target, "qr_code_contact_bw.png"] do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb #{private_flags} -f photo:qr_code_contact_bw > #{TARGET_DIR}/resume_private_bw.tex"
end


file "#{TARGET_DIR}/resume_public.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.md.erb #{public_flags} > #{TARGET_DIR}/resume_public.md"
end

file "#{TARGET_DIR}/resume_short.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.md.erb > #{TARGET_DIR}/resume_short.md"
end

file "#{TARGET_DIR}/resume_public.html"  => [:make_target] do |t|
    sh "templator/templator -d #{data_files} resume.html.erb #{public_flags} > #{TARGET_DIR}/resume_public.html"
end

task :latex_public => ["#{TARGET_DIR}/resume_public.tex", :copy_deps, "qr_code_url.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && pdflatex resume_public.tex"
  rm "#{TARGET_DIR}/resume_public.tex"
end

desc "Make full resume PDF"
task :latex_full => ["#{TARGET_DIR}/resume_full.tex", :copy_deps, "qr_code_contact.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && pdflatex resume_full.tex"
  rm "#{TARGET_DIR}/resume_full.tex"
end

task :latex_private => ["#{TARGET_DIR}/resume_private.tex", :copy_deps, "qr_code_contact.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && pdflatex resume_private.tex"
  rm "#{TARGET_DIR}/resume_private.tex"
  FileUtils.cp_r File.join(TARGET_DIR, "resume_private.pdf"), File.join(TARGET_DIR, "RodHilton_resume.pdf")
end

task :latex_private_bw => ["#{TARGET_DIR}/resume_private_bw.tex", :copy_deps, "qr_code_contact.png"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=latex && pdflatex resume_private_bw.tex"
  #rm "#{TARGET_DIR}/resume_private_bw.tex"
end
  
desc "Make private resume PDF"
task :resume_private => [:latex_private, :latex_private_bw]

desc "Make public resume PDF"
task :resume_public => [:latex_public, "#{TARGET_DIR}/resume_public.html", "#{TARGET_DIR}/resume_public.md", "#{TARGET_DIR}/resume_short.md"]

desc "Make all resumes"
task :all => [:resume_public, :resume_private]

desc "Upload resume to web site"
task :upload_resume => [:resume_public] do |t|
  pub = YAML.load_file("public.yaml")
  host = pub["host"]
  path = pub["path"]
  abort("Missing required values in public.yaml") if host.nil? or path.nil?
  sh "scp -P 7822 #{TARGET_DIR}/resume_public.html #{TARGET_DIR}/resume_public.pdf #{host}:#{path}"
end
