require 'rake/clean'
require 'yaml'

task :default => [:all]

TARGET_DIR="out"

CLEAN.include(TARGET_DIR)

data_files = "resume.yaml,skills.yaml"

task :make_target do |t|
  Dir.mkdir(TARGET_DIR) unless File.exists?(TARGET_DIR)
end

file "#{TARGET_DIR}/resume_public.tex"  => [:make_target] do |t|
  #sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
  sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_url -f expand_school -f certifications -f complete_history > #{TARGET_DIR}/resume_public.tex"
end

file "#{TARGET_DIR}/resume_full.tex"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_url -f expand_school -f certifications -f complete_history > #{TARGET_DIR}/resume_full.tex"
end

file "#{TARGET_DIR}/resume_public.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} resume.md.erb > #{TARGET_DIR}/resume_public.md"
end

task :latex_public => ["#{TARGET_DIR}/resume_public.tex"] do |t|
  sh "pdflatex --output-directory=#{TARGET_DIR} #{TARGET_DIR}/resume_public.tex"
  rm "#{TARGET_DIR}/resume_public.tex"
end

task :latex_full => ["#{TARGET_DIR}/resume_full.tex"] do |t|
  sh "pdflatex --output-directory=#{TARGET_DIR} #{TARGET_DIR}/resume_full.tex"
  rm "#{TARGET_DIR}/resume_full.tex"
end
  
file "#{TARGET_DIR}/resume_private.tex"  => [:make_target] do |t|
  contact = YAML.load_file("contact.yaml")
  email = contact["email"]
  phone = contact["phone"]
  abort("Missing required values in contact.yaml") if email.nil? or phone.nil?
  sh "templator/templator -d #{data_files} resume.tex.erb -f photo:qr_code_contact -f \"email:#{email}\" -f \"phone:#{phone}\" > #{TARGET_DIR}/resume_private.tex"
end

task :latex_private => ["#{TARGET_DIR}/resume_private.tex"] do |t|
  sh "pdflatex --output-directory=#{TARGET_DIR} #{TARGET_DIR}/resume_private.tex"
  rm "#{TARGET_DIR}/resume_private.tex"
end
  
task :latex => [:latex_public, :latex_private, :latex_full]

file "#{TARGET_DIR}/resume_public.html"  => [:make_target] do |t|
    sh "templator/templator -d #{data_files} resume.html.erb > #{TARGET_DIR}/resume_public.html"
end

task :resume_public => ["#{TARGET_DIR}/resume_public.html", "#{TARGET_DIR}/resume_public.md"]

task :all => [:resume_public, :latex]

task :upload_resume => [:resume_public, :latex_public] do |t|
  pub = YAML.load_file("public.yaml")
  host = pub["host"]
  path = pub["path"]
  abort("Missing required values in public.yaml") if host.nil? or path.nil?
  sh "scp -P 7822 #{TARGET_DIR}/resume_public.html #{TARGET_DIR}/resume_public.pdf #{host}:#{path}"
end
