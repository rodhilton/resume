require 'rake/clean'
require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'open3'

TARGET_DIR="docs"
TEMPLATES_DIR="templates"
RESOURCES_DIR="resources"
IMAGES_DIR=File.join(RESOURCES_DIR, "images")
LATEX_DIR=File.join(RESOURCES_DIR, "latex")
FONTS_DIR=File.join(RESOURCES_DIR, "fonts")
SITE_RESOURCES_DIR=File.join(RESOURCES_DIR, "site")
GEMINI_PROMPT_FILE=File.join(TEMPLATES_DIR, "gemini_resume_prompt.txt")
GEMINI_KEY_FILE=".gemini_api_key"
GEMINI_MODEL_OVERRIDE=ENV["GEMINI_MODEL"]
WEASYPRINT_CSS=File.join(RESOURCES_DIR, "css", "weasyprint_resume.css")
DATA_FILES="resume.yaml"
FULL_FLAGS = "-f expand_school -f certifications -f complete_history -f publications -f projects"

CLEAN.include(TARGET_DIR)

file "qr_code_contact.png" => [:make_target] do |t|
  run_cmd "templator/templator -d resume.yaml,contact.yaml #{File.join(TEMPLATES_DIR, 'qr_code_contact.txt.erb')} > qr_code_contact.txt"
  run_cmd "cat qr_code_contact.txt | qrencode -o #{TARGET_DIR}/qr_code_contact.png -t png -m 0 --size=20 --foreground=414141"
  run_rm_f "qr_code_contact.txt"
end

file "qr_code_contact.pdf" => [:make_target, "qr_code_contact.png"] do |t|
  run_magick("#{TARGET_DIR}/qr_code_contact.png #{TARGET_DIR}/qr_code_contact.pdf")
end

file "qr_code_url.png" => [:make_target] do |t|
  run_cmd "templator/templator -d resume.yaml #{File.join(TEMPLATES_DIR, 'qr_code_url.txt.erb')} > qr_code_url.txt"
  run_cmd "cat qr_code_url.txt | qrencode -o #{TARGET_DIR}/qr_code_url.png -t png -m 0 --size=20 --foreground=414141"
  run_rm_f "qr_code_url.txt"
end

file "profile.jpg" => [:make_target] do |t|
  run_cmd "cp #{File.join(IMAGES_DIR, 'profile.jpg')} #{TARGET_DIR}/profile.jpg"
end

file "profile_circle.png" => [:make_target] do |t|
  source = File.join(IMAGES_DIR, "profile.jpg")
  mask = "\\( -size 512x512 xc:none -fill white -draw \"circle 256,256 256,0\" \\)"
  output = "#{TARGET_DIR}/profile_circle.png"
  run_magick("#{source} -alpha on -resize 512x512^ -gravity center -extent 512x512 #{mask} -compose copyopacity -composite #{output}")
end

file "profile.pdf" => [:make_target, "profile.jpg"] do |t|
  run_magick("#{TARGET_DIR}/profile.jpg #{TARGET_DIR}/profile.pdf")
end

file "profile_circle.pdf" => [:make_target, "profile_circle.png"] do |t|
  run_magick("#{TARGET_DIR}/profile_circle.png #{TARGET_DIR}/profile_circle.pdf")
end

file "#{TARGET_DIR}/resume_full.tex"  => [:make_target] do |t|
  #sh "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f photo:qr_code_url > #{TARGET_DIR}/resume_full.tex"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f color #{FULL_FLAGS} -f highlight:true -f color:33627f -f photo_shape:rectangle -f skills_summary -f socials -f expand_school -f show_projects -f photo:profile_circle > #{TARGET_DIR}/resume_full.tex"
end

file "#{TARGET_DIR}/resume.tex"  => [:make_target] do |t|
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f color #{base_flags} -f highlight:false -f color:414141 -f photo_shape:rectangle -f expand_coursework -f photo:qr_code_contact > #{TARGET_DIR}/resume.tex"
end

file "#{TARGET_DIR}/resume_downloadable.typ"  => [:make_target] do |t|
  #sh "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f photo:qr_code_url > #{TARGET_DIR}/resume_full.tex"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.typ.erb')} -f highlight:true -f color:33627f -f photo_shape:rectangle -f skills_summary -f socials -f show_projects -f photo:profile_circle > #{TARGET_DIR}/resume_downloadable.typ"
end

file "#{TARGET_DIR}/resume_full.md" => [:make_target] do |t|
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.md.erb')} #{md_full_flags} > #{TARGET_DIR}/resume_full.md"
end

file "#{TARGET_DIR}/resume.md" => [:make_target] do |t|
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.md.erb')} > #{TARGET_DIR}/resume.md"
end

file "#{TARGET_DIR}/resume_parseable.txt" => [:make_target] do |t|
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.txt.erb')} #{base_flags} > #{TARGET_DIR}/resume_parseable.txt"
end

file "#{TARGET_DIR}/resume_full.html"  => [:make_target] do |t|
    run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'resume.html.erb')} #{FULL_FLAGS} > #{TARGET_DIR}/resume_full.html"
end

task :make_target do |t|
  Dir.mkdir(TARGET_DIR) unless File.exists?(TARGET_DIR)
end

task :copy_deps do |t|
  run_cp_r File.join(LATEX_DIR, "." ), File.join(TARGET_DIR, "latex")
  run_cp_r FONTS_DIR, File.join(TARGET_DIR, "fonts")
end

desc "Make full resume PDF"
task :pdf_full => ["#{TARGET_DIR}/resume_full.tex", :copy_deps, "profile_circle.pdf"] do |t|
  run_xelatex("resume_full.tex")
  run_rm_f "#{TARGET_DIR}/resume_full.tex"
  run_rm_f [
    "#{TARGET_DIR}/resume_full.aux",
    "#{TARGET_DIR}/resume_full.log",
    "#{TARGET_DIR}/resume_full.out",
    "#{TARGET_DIR}/profile_circle.pdf",
  ]
end

desc "Make resume PDF"
task :pdf => ["#{TARGET_DIR}/resume.tex", :copy_deps, "qr_code_contact.pdf"] do |t|
  run_xelatex("resume.tex")
  run_rm_f "#{TARGET_DIR}/resume.tex"
  run_cp_r File.join(TARGET_DIR, "resume.pdf"), File.join(TARGET_DIR, "RodHilton_resume.pdf")
  run_rm_f [
    "#{TARGET_DIR}/resume.aux",
    "#{TARGET_DIR}/resume.log",
    "#{TARGET_DIR}/resume.out",
    "#{TARGET_DIR}/qr_code_contact.pdf",
    "#{TARGET_DIR}/qr_code_contact.png"
  ]
end

desc "Make downloadable resume PDF (Typst)"
task :downloadable => ["#{TARGET_DIR}/resume_downloadable.typ", :copy_deps, "profile_circle.png"] do |t|
  run_cp_r FONTS_DIR, File.join(TARGET_DIR, "fonts")
  run_cmd "cd #{TARGET_DIR}; TYPST_FONT_PATHS=./fonts typst compile resume_downloadable.typ"
  run_rm_f "#{TARGET_DIR}/resume_downloadable.typ"
end

desc "Build parseable resume text for job portals"
task :parseable => ["#{TARGET_DIR}/resume_parseable.txt", :copy_deps] do |t|
end

desc "Build single-page web site includes"
task :site => [:make_target] do |t|
  site_root = File.join(TARGET_DIR, "rodhilton.com")
  run_mkdir_p site_root
  if Dir.exist?(SITE_RESOURCES_DIR)
    run_cp_r File.join(SITE_RESOURCES_DIR, "."), site_root
  end
  run_mkdir_p File.join(site_root, "img")
  run_mkdir_p File.join(site_root, "_includes")
  run_cp Dir.glob(File.join(IMAGES_DIR, "*")), File.join(site_root, "img")
  # run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.index.html.erb')} > #{File.join(site_root, 'index.html')}"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.com.about.html.erb')} > #{File.join(site_root, '_includes', 'about.html')}"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.com.experience.html.erb')} > #{File.join(site_root, '_includes', 'experience.html')}"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.com.education.html.erb')} > #{File.join(site_root, '_includes', 'education.html')}"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.com.skills.html.erb')} > #{File.join(site_root, '_includes', 'skills.html')}"
  run_cmd "templator/templator -d #{DATA_FILES} #{File.join(TEMPLATES_DIR, 'rodhilton.com.projects.html.erb')} > #{File.join(site_root, '_includes', 'projects.html')}"
end

desc "Generate resume markdown"
task :markdown => "#{TARGET_DIR}/resume.md"

desc "Generate full resume markdown"
task :markdown_full => "#{TARGET_DIR}/resume_full.md"

desc "Generate full resume HTML"
task :html => "#{TARGET_DIR}/resume_full.html"

desc "Make base resume outputs"
task :resume => [:pdf, :parseable, :markdown, :downloadable, :html]

desc "Make full resume outputs"
task :resume_full => [:pdf_full, :markdown_full]

desc "Make all resumes"
task :all => [:resume, :resume_full, :site]

desc "Generate tailored resume and cover letter from stdin"
task :tailored => [:make_target, :markdown_full] do |t, args|
  job_description = read_job_description("tailored")

  api_key = read_gemini_api_key
  if api_key.nil? || api_key.strip.empty?
    abort("Missing Gemini API key. Set GEMINI_API_KEY or add #{GEMINI_KEY_FILE}.")
  end

  resume_text = File.read("#{TARGET_DIR}/resume_full.md")
  prompt = read_gemini_prompt(job_description, resume_text)

  model_name = resolve_gemini_model(api_key)
  output_text = gemini_generate(prompt, api_key, model_name)
  resume_md, cover_md = split_gemini_output(output_text)

  File.write("#{TARGET_DIR}/resume_tailored.md", resume_md)
  File.write("#{TARGET_DIR}/cover_letter.md", cover_md)

  warn("Gemini response missing cover letter section; wrote full output to resume_tailored.md.") if cover_md.to_s.strip.empty?
  Rake::Task[:tailored_pdf].invoke
ensure
  # FileUtils.rm_f "#{TARGET_DIR}/resume_full.md"
end

desc "Render existing tailored markdown files to PDFs"
task :tailored_pdf => [:make_target] do |t|
  resume_md = "#{TARGET_DIR}/resume_tailored.md"
  cover_md = "#{TARGET_DIR}/cover_letter.md"

  abort("Missing #{resume_md}. Run: cat job.txt | rake tailored") unless File.exist?(resume_md)
  abort("Missing #{cover_md}. Run: cat job.txt | rake tailored") unless File.exist?(cover_md)

  render_markdown_pdf(resume_md, "#{TARGET_DIR}/resume_tailored.pdf")
  render_markdown_pdf(cover_md, "#{TARGET_DIR}/cover_letter.pdf")
end

task :default => [:all]

def colorize(text, color_code)
  return text unless $stdout.tty?

  "\e[#{color_code}m#{text}\e[0m"
end

def info(message)
  puts colorize(message, 33)
end

def run_cmd(command)
  puts colorize(command, 36)
  sh command, verbose: false
end

def run_rm_f(*paths)
  paths.flatten.each do |path|
    puts colorize("rm -f #{path}", 31)
  end
  FileUtils.rm_f(*paths)
end

def run_cp_r(src, dest)
  puts colorize("cp -r #{src} #{dest}", 32)
  FileUtils.cp_r(src, dest)
end

def run_cp(src, dest)
  puts colorize("cp #{src} #{dest}", 32)
  FileUtils.cp(src, dest)
end

def run_mkdir_p(path)
  puts colorize("mkdir -p #{path}", 34)
  FileUtils.mkdir_p(path)
end

def base_flags 
  contact = YAML.load_file("contact.yaml")
  email = contact["email"]
  phone = contact["phone"]
  abort("Missing required values in contact.yaml") if email.nil? or phone.nil?
  "-f \"email:#{email}\" -f \"phone:#{phone}\""
end

def md_full_flags
  "#{FULL_FLAGS} #{base_flags} -f full -f include_contact -f include_interests -f include_job_meta -f include_job_summary -f include_job_tech"
end

def read_gemini_api_key
  return ENV["GEMINI_API_KEY"] unless ENV["GEMINI_API_KEY"].to_s.strip.empty?
  return nil unless File.exist?(GEMINI_KEY_FILE)

  File.read(GEMINI_KEY_FILE).to_s.strip
end

def read_gemini_prompt(job_description, resume_text)
  abort("Missing prompt file: #{GEMINI_PROMPT_FILE}") unless File.exist?(GEMINI_PROMPT_FILE)

  prompt = File.read(GEMINI_PROMPT_FILE)
  if prompt.include?("{{JOB_DESCRIPTION}}") || prompt.include?("{{RESUME}}")
    prompt = prompt.gsub("{{JOB_DESCRIPTION}}", job_description)
    prompt = prompt.gsub("{{RESUME}}", resume_text)
    return prompt
  end

  [
    prompt,
    "Job Description:",
    job_description,
    "Full Resume:",
    resume_text
  ].join("\n\n")
end

def list_gemini_models(api_key)
  uri = URI("https://generativelanguage.googleapis.com/v1beta/models?key=#{api_key}")
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.get(uri.request_uri)
  end

  unless response.is_a?(Net::HTTPSuccess)
    abort("Gemini models request failed: #{response.code} #{response.message}\n#{response.body}")
  end

  body = JSON.parse(response.body)
  Array(body["models"])
end

def format_model_limits(model)
  limits = Array(model["rateLimits"])
  return "quota: unknown" if limits.empty?

  details = limits.map do |limit|
    name = limit["name"] || "quota"
    size = limit["limit"]
    interval = limit["interval"] || limit["intervalUnit"] || "unknown"
    "#{name}=#{size}/#{interval}"
  end

  "quota: #{details.join(", ")}"
end

def resolve_gemini_model(api_key)
  if GEMINI_MODEL_OVERRIDE && !GEMINI_MODEL_OVERRIDE.to_s.strip.empty?
    warn("Using GEMINI_MODEL override: #{GEMINI_MODEL_OVERRIDE}")
    return GEMINI_MODEL_OVERRIDE
  end

  models = list_gemini_models(api_key)
  abort("No Gemini models available for this API key") if models.empty?

  candidates = models.select do |model|
    methods = Array(model["supportedGenerationMethods"])
    methods.include?("generateContent")
  end
  selected = (candidates.first || models.first)
  selected_name = selected["name"] || selected.to_s

  info("Selected model: #{selected_name}")
  selected_name
end

def normalize_model_name(model_name)
  return model_name if model_name.to_s.start_with?("models/")

  "models/#{model_name}"
end

def read_job_description(usage_task)
  if STDIN.tty?
    abort("Usage: cat job.txt | rake #{usage_task}")
  end

  STDIN.read
end

def gemini_generate(prompt, api_key, model_name)
  model_path = normalize_model_name(model_name)
  uri = URI("https://generativelanguage.googleapis.com/v1beta/#{model_path}:generateContent?key=#{api_key}")
  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(
    {
      contents: [
        {
          role: "user",
          parts: [{ text: prompt }]
        }
      ]
    }
  )

  info("Calling Gemini...") if $stdout.tty?
  stop_progress = false
  progress = Thread.new do
    next unless $stdout.tty?
    $stdout.sync = true
    until stop_progress
      print(".")
      sleep 1
    end
  end

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    abort("Gemini request failed: #{response.code} #{response.message}\n#{response.body}")
  end

  body = JSON.parse(response.body)
  text = body.dig("candidates", 0, "content", "parts")
             &.map { |part| part["text"] }
             &.join("\n")

  abort("Gemini response missing text content") if text.nil? || text.strip.empty?

  text
ensure
  stop_progress = true
  if progress
    progress.join(2)
    info("") if $stdout.tty?
  end
end

def split_gemini_output(text)
  resume_marker = "===RESUME==="
  cover_marker = "===COVER_LETTER==="

  if text.include?(resume_marker) && text.include?(cover_marker)
    resume_section = text.split(resume_marker, 2)[1]
    resume_text, cover_text = resume_section.split(cover_marker, 2)
    return resume_text.to_s.strip, cover_text.to_s.strip
  end

  [text.to_s.strip, ""]
end

def render_markdown_pdf(source_md, output_pdf)
  html_path = source_md.sub(/\.md\z/, ".html")
  html_body, status = Open3.capture2("cmark-gfm", source_md)
  abort("cmark-gfm failed for #{source_md}") unless status.success?
  html = <<~HTML
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
      </head>
      <body>
    #{html_body}
      </body>
    </html>
  HTML
  File.write(html_path, html)
  run_cmd "weasyprint #{html_path} #{output_pdf} --stylesheet #{WEASYPRINT_CSS}"
  run_rm_f html_path
end

def run_magick(args)
  if system("command -v magick >/dev/null 2>&1")
    run_cmd "magick #{args}"
  else
    run_cmd "convert #{args}"
  end
end

def run_xelatex(tex_filename)
  cmd = "cd #{TARGET_DIR}; TEXINPUTS=./latex//:${TEXINPUTS} xelatex #{tex_filename}"
  output, status = Open3.capture2e(cmd)
  return if status.success?

  warn(output)
  abort("xelatex failed for #{tex_filename}")
end
