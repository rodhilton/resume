require 'rake/clean'
require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'open3'

task :default => [:all]

TARGET_DIR="docs"
TEMPLATES_DIR="templates"
RESOURCES_DIR="resources"
IMAGES_DIR=File.join(RESOURCES_DIR, "images")
LATEX_DIR=File.join(RESOURCES_DIR, "latex")
SITE_RESOURCES_DIR=File.join(RESOURCES_DIR, "site")
GEMINI_PROMPT_FILE=File.join(TEMPLATES_DIR, "gemini_resume_prompt.txt")
GEMINI_KEY_FILE=".gemini_api_key"
GEMINI_MODEL_OVERRIDE=ENV["GEMINI_MODEL"]
WEASYPRINT_CSS=File.join(RESOURCES_DIR, "css", "weasyprint_resume.css")

CLEAN.include(TARGET_DIR)

data_files = "resume.yaml"

public_flags = "-f expand_school -f certifications -f complete_history -f publications"

def private_flags 
  contact = YAML.load_file("contact.yaml")
  email = contact["email"]
  phone = contact["phone"]
  abort("Missing required values in contact.yaml") if email.nil? or phone.nil?
  "-f \"email:#{email}\" -f \"phone:#{phone}\""
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

  puts("Selected model: #{selected_name}")
  selected_name
end

def normalize_model_name(model_name)
  return model_name if model_name.to_s.start_with?("models/")

  "models/#{model_name}"
end

def read_job_description(job_path, usage_task)
  if job_path.nil?
    if STDIN.tty?
      abort("Usage: rake #{usage_task}[job_description.txt] or cat job.txt | rake \"#{usage_task}[-]\"")
    end
    return STDIN.read
  end

  if job_path == "-"
    return STDIN.read
  end

  abort("Job description file not found: #{job_path}") unless File.exist?(job_path)
  File.read(job_path)
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

  puts("Calling Gemini...") if $stdout.tty?
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
    puts("") if $stdout.tty?
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

task :make_target do |t|
  Dir.mkdir(TARGET_DIR) unless File.exists?(TARGET_DIR)
end

file "qr_code_contact.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml,contact.yaml #{File.join(TEMPLATES_DIR, 'qr_code_contact.txt.erb')} > qr_code_contact.txt"
  sh "cat qr_code_contact.txt | qrencode -o #{TARGET_DIR}/qr_code_contact.png -t png -m 0 --size=20 --foreground=414141"
  rm "qr_code_contact.txt"
end

file "qr_code_contact.pdf" => [:make_target, "qr_code_contact.png"] do |t|
  sh "convert #{TARGET_DIR}/qr_code_contact.png #{TARGET_DIR}/qr_code_contact.pdf"
end

file "qr_code_url.png" => [:make_target] do |t|
  sh "templator/templator -d resume.yaml #{File.join(TEMPLATES_DIR, 'qr_code_url.txt.erb')} > qr_code_url.txt"
  sh "cat qr_code_url.txt | qrencode -o #{TARGET_DIR}/qr_code_url.png -t png -m 0 --size=20 --foreground=414141"
  rm "qr_code_url.txt"
end

file "profile.jpg" => [:make_target] do |t|
  sh "cp #{File.join(IMAGES_DIR, 'profile.jpg')} #{TARGET_DIR}/profile.jpg"
end

file "profile_circle.png" => [:make_target] do |t|
  source = File.join(IMAGES_DIR, "profile.jpg")
  mask = "\\( -size 512x512 xc:none -fill white -draw \"circle 256,256 256,0\" \\)"
  output = "#{TARGET_DIR}/profile_circle.png"
  if system("command -v magick >/dev/null 2>&1")
    sh "magick #{source} -alpha on -resize 512x512^ -gravity center -extent 512x512 #{mask} -compose copyopacity -composite #{output}"
  else
    sh "convert #{source} -alpha on -resize 512x512^ -gravity center -extent 512x512 #{mask} -compose copyopacity -composite #{output}"
  end
end

file "profile.pdf" => [:make_target, "profile.jpg"] do |t|
  sh "convert #{TARGET_DIR}/profile.jpg #{TARGET_DIR}/profile.pdf"
end

file "profile_circle.pdf" => [:make_target, "profile_circle.png"] do |t|
  sh "convert #{TARGET_DIR}/profile_circle.png #{TARGET_DIR}/profile_circle.pdf"
end

task :copy_deps do |t|
  FileUtils.cp_r File.join(LATEX_DIR, "." ), File.join(TARGET_DIR, "latex")
  FileUtils.cp_r File.join(LATEX_DIR, "fonts"), File.join(TARGET_DIR, "fonts")
end

file "#{TARGET_DIR}/resume_public.tex"  => [:make_target] do |t|
  #sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f color #{public_flags} -f highlight:true -f color:33627f -f photo_shape:rectangle -f skills_summary -f socials -f expand_school -f show_projects -f photo:profile_circle > #{TARGET_DIR}/resume_public.tex"
end

file "#{TARGET_DIR}/resume_private.tex"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f color #{private_flags} -f highlight:false -f color:414141 -f photo_shape:rectangle -f expand_coursework -f photo:qr_code_contact > #{TARGET_DIR}/resume_private.tex"
end

file "#{TARGET_DIR}/resume_public_typ.typ"  => [:make_target] do |t|
  #sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.tex.erb')} -f photo:qr_code_url > #{TARGET_DIR}/resume_public.tex"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.typ.erb')} -f highlight:true -f color:33627f -f photo_shape:rectangle -f skills_summary -f socials -f show_projects -f photo:profile_circle > #{TARGET_DIR}/resume_public_typ.typ"
end

file "#{TARGET_DIR}/resume_private_typ.typ"  => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.typ.erb')} -f color #{private_flags} -f highlight:false -f color:414141 -f photo_shape:rectangle -f expand_coursework -f photo:qr_code_contact.png > #{TARGET_DIR}/resume_private_typ.typ"
end

file "#{TARGET_DIR}/resume_public.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.md.erb')} #{public_flags} > #{TARGET_DIR}/resume_public.md"
end

file "#{TARGET_DIR}/resume_short.md" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.md.erb')} > #{TARGET_DIR}/resume_short.md"
end

file "#{TARGET_DIR}/resume.txt" => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.txt.erb')} #{public_flags} > #{TARGET_DIR}/resume.txt"
end

file "#{TARGET_DIR}/resume_full.txt" => [:make_target] do |t|
  sh "templator/templator -d #{data_files},contact.yaml #{File.join(TEMPLATES_DIR, 'resume_full.txt.erb')} -f complete_history -f publications -f certifications > #{TARGET_DIR}/resume_full.txt"
end

file "#{TARGET_DIR}/resume_public.html"  => [:make_target] do |t|
    sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.html.erb')} #{public_flags} > #{TARGET_DIR}/resume_public.html"
end

desc "Make public resume HTML"
task :html_public => "#{TARGET_DIR}/resume_public.html" do |t|
  sh "cp #{TARGET_DIR}/resume_public.html #{TARGET_DIR}/index.html"
end

desc "Make public resume HTML (inlineable)"
task :html_public_inline => [:make_target] do |t|
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'resume.html.erb')} #{public_flags} -f inline > #{TARGET_DIR}/resume_public_inline.html"
end

desc "Make full resume PDF (LaTeX)"
task :latex_full => ["#{TARGET_DIR}/resume_public.tex", :copy_deps, "profile_circle.pdf"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=./latex//:${TEXINPUTS} xelatex resume_public.tex"
  rm "#{TARGET_DIR}/resume_public.tex"
  FileUtils.rm_f [
    "#{TARGET_DIR}/resume_public.aux",
    "#{TARGET_DIR}/resume_public.log",
    "#{TARGET_DIR}/resume_public.out",
    "#{TARGET_DIR}/profile_circle.pdf",
    "#{TARGET_DIR}/profile_circle.png"
  ]
end

task :latex_private => ["#{TARGET_DIR}/resume_private.tex", :copy_deps, "qr_code_contact.pdf"] do |t|
  sh "cd #{TARGET_DIR}; TEXINPUTS=./latex//:${TEXINPUTS} xelatex resume_private.tex"
  rm "#{TARGET_DIR}/resume_private.tex"
  FileUtils.cp_r File.join(TARGET_DIR, "resume_private.pdf"), File.join(TARGET_DIR, "RodHilton_resume.pdf")
  FileUtils.rm_f [
    "#{TARGET_DIR}/resume_private.aux",
    "#{TARGET_DIR}/resume_private.log",
    "#{TARGET_DIR}/resume_private.out",
    "#{TARGET_DIR}/qr_code_contact.pdf",
    "#{TARGET_DIR}/qr_code_contact.png"
  ]
end

desc "Make public resume PDF (Typst)"
task :typst_public => ["#{TARGET_DIR}/resume_public_typ.typ", :copy_deps, "profile_circle.png"] do |t|
  FileUtils.cp_r File.join(LATEX_DIR, "fonts"), File.join(TARGET_DIR, "fonts")
  sh "cd #{TARGET_DIR}; TYPST_FONT_PATHS=./fonts typst compile resume_public_typ.typ"
  rm "#{TARGET_DIR}/resume_public_typ.typ"
end

task :resume_full_txt => ["#{TARGET_DIR}/resume_full.txt", :copy_deps] do |t|
end

task :parseable_txt => ["#{TARGET_DIR}/resume.txt", :copy_deps] do |t|
end

desc "Build single-page web site"
task :rodhilton_site => [:make_target] do |t|
  site_root = File.join(TARGET_DIR, "rodhilton.com")
  FileUtils.mkdir_p site_root
  FileUtils.cp_r File.join(SITE_RESOURCES_DIR, "."), site_root
  FileUtils.mkdir_p File.join(site_root, "img")
  FileUtils.mkdir_p File.join(site_root, "_includes")
  FileUtils.cp Dir.glob(File.join(IMAGES_DIR, "*")), File.join(site_root, "img")
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.index.html.erb')} > #{File.join(site_root, 'index.html')}"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.com.about.html.erb')} > #{File.join(site_root, '_includes', 'about.html')}"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.com.experience.html.erb')} > #{File.join(site_root, '_includes', 'experience.html')}"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.com.education.html.erb')} > #{File.join(site_root, '_includes', 'education.html')}"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.com.skills.html.erb')} > #{File.join(site_root, '_includes', 'skills.html')}"
  sh "templator/templator -d #{data_files} #{File.join(TEMPLATES_DIR, 'rodhilton.com.projects.html.erb')} > #{File.join(site_root, '_includes', 'projects.html')}"
end

desc "Make private resume PDF"
task :resume_private => [:latex_private, :parseable_txt]

desc "Make public resume PDF"
task :resume_public => [:latex_full, :typst_public, :html_public, "#{TARGET_DIR}/resume_public.md", "#{TARGET_DIR}/resume_short.md"]

desc "Make all resumes"
task :all => [:resume_public, :resume_private]

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
  sh "weasyprint #{html_path} #{output_pdf} --stylesheet #{WEASYPRINT_CSS}"
  rm html_path
end

# Usage examples:
#   rake tailor[path/to/job_description.txt]
#   rake "tailor[docs/job_description.txt]"
#   cat job.txt | rake "tailor[-]"
# Note: brackets are part of the rake argument syntax, and quotes are needed
# if your shell treats them specially (spaces or globbing).
desc "Generate tailored resume and cover letter markdown from a job description file"
task :tailor, [:job_description] => [:make_target, "#{TARGET_DIR}/resume_full.txt"] do |t, args|
  job_path = args[:job_description]
  job_description = read_job_description(job_path, "tailor")

  api_key = read_gemini_api_key
  if api_key.nil? || api_key.strip.empty?
    abort("Missing Gemini API key. Set GEMINI_API_KEY or add #{GEMINI_KEY_FILE}.")
  end

  resume_text = File.read("#{TARGET_DIR}/resume_full.txt")
  prompt = read_gemini_prompt(job_description, resume_text)

  model_name = resolve_gemini_model(api_key)
  output_text = gemini_generate(prompt, api_key, model_name)
  resume_md, cover_md = split_gemini_output(output_text)

  File.write("#{TARGET_DIR}/resume_tailored.md", resume_md)
  File.write("#{TARGET_DIR}/cover_letter.md", cover_md)

  warn("Gemini response missing cover letter section; wrote full output to resume_tailored.md.") if cover_md.to_s.strip.empty?
ensure
  FileUtils.rm_f "#{TARGET_DIR}/resume_full.txt"
end

desc "Render existing tailored markdown files to PDFs"
task :tailor_pdf => [:make_target] do |t|
  resume_md = "#{TARGET_DIR}/resume_tailored.md"
  cover_md = "#{TARGET_DIR}/cover_letter.md"

  abort("Missing #{resume_md}. Run rake tailor[...] first.") unless File.exist?(resume_md)
  abort("Missing #{cover_md}. Run rake tailor[...] first.") unless File.exist?(cover_md)

  render_markdown_pdf(resume_md, "#{TARGET_DIR}/resume_tailored.pdf")
  render_markdown_pdf(cover_md, "#{TARGET_DIR}/cover_letter.pdf")
end
