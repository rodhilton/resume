MAX_JOB_AGE=10
MAX_ACCOMPLISHMENTS=4
MIN_ACCOMPLISHMENTS=2

SKILL_ORDER_DECAY = 0.08 #How much value a skill decays by (starting at 1) as its placement in the list moves down
SKILL_YEARLY_DECAY = 0.1
YEAR_CUTOFF = 7

def extract_year(date)

  if date.nil? or date == "Present"
    "Present"
  else
    date[-4..-1]
  end
end

def timespan(start_date, end_date)
  end_year = extract_year(end_date)

  start_year=extract_year(start_date)

  return "#{start_year}-#{end_year}"

end


def calculate_skills(jobs, order_decay=SKILL_ORDER_DECAY, yearly_decay=SKILL_YEARLY_DECAY, year_cutoff=YEAR_CUTOFF, max=13)

  years_and_skills = {}
  skill_last_used = {}

  jobs.each do |job|
    start_year = extract_year(job.start_time)
    end_year = extract_year(job.end_time).gsub("Present", Time.new.year.to_s)

    if !job.technologies.nil? 
      skill_list = job.technologies.split(/,/).collect{|s| s.strip} unless job.technologies.nil?
      start_year.to_i.upto(end_year.to_i) do |year|
        skill_list.each_with_index do |skill, i|
          
          decay_amt = (1-order_decay)**i
          if !years_and_skills.key?(year) 
            years_and_skills[year] = []
          end
          years_and_skills[year] << [skill, decay_amt]

          if !skill_last_used.key?(skill)
            skill_last_used[skill] = 0
          end
          if year > skill_last_used[skill]
            skill_last_used[skill] = year
          end

        end
      end
    end
  end

  skills_counts = {}

  years_and_skills.each do |year, skills|
    skills.each do |skill_and_score|
      skill, score = skill_and_score
      if !skills_counts.key?(skill)
        skills_counts[skill]=0
      end
      skills_counts[skill] = skills_counts[skill]+score
    end
  end

  #decay based on how long ago used
  skills_counts.each do |skill, score|
    years_ago_used = Time.new.year - skill_last_used[skill]
    decay_amt = (1-yearly_decay)**years_ago_used
    skills_counts[skill] = skills_counts[skill]*decay_amt
  end

  sum = 0.0
  max_skill_value = 0
  min_skill_value = 999999999

  skills_counts.each do |skill, value|
      if(value < min_skill_value)
        min_skill_value = value
      end

      if(value > max_skill_value)
        max_skill_value = value
      end

      sum = sum + value
  end

  skills_counts.delete_if do |skill, score|
    years_ago_used = Time.new.year - skill_last_used[skill]
    years_ago_used >= year_cutoff
  end

  mean = sum / skills_counts.size.to_i

  var_sum = skills_counts.collect { |k, v| v }.inject(0) do |accum, i| 
    accum +(i-mean)**2
  end
  variance = var_sum/(skills_counts.length - 1).to_f

  std_dev = Math.sqrt(variance)

  accomplished = skills_counts.select{|skill, value| value >= mean + std_dev/2}
  advanced = skills_counts.select{|skill, value| value < mean + std_dev/2 and value >= mean - std_dev / 2}
  novice = skills_counts.select{|skill, value| value < mean - std_dev / 2}

  def listify(skill_list, max) 
    skill_list.map{|s, v| [s, v]}.sort_by{|sv| sv[1]}.reverse.map{|sv| sv[0]}.take(max).join(", ")
  end

  accomplished_list = listify(accomplished, max)
  advanced_list = listify(advanced, max)
  novice_list = listify(novice, max)

  {
   :accomplished=> accomplished_list,
   :advanced=> advanced_list,
   :novice=> novice_list
  }

end

def display_schoolyear(degree, expand_school_flag= false, before = "(", after=")") 

  endyear = extract_year(degree.end_time).gsub("Present", Time.new.year.to_s).to_i
  if(endyear > Time.new.year) 
  	"#{before}Expected #{endyear}#{after}"
#    "#{before}In Progress#{after}"
  elsif(expand_school_flag)
  	"#{before}#{endyear}#{after}"
  else
  	""
  end
end

def skill_to_icons(skillname)
  if(skillname.downcase == "html/css") 
    ["html5", "css3"]
  elsif(skillname.downcase == "aws") 
    ["amazonwebservices"]
  elsif(skillname.downcase == "kafka")
    ["apachekafka"]
  else
    [skillname]
  end
end

def unique_skills(skills)
	skills.sort_by{|s| s["rating"] }.reverse.inject([]) { |memo,x| memo << x unless memo.detect { |item| item["name"] == x["name"] }; memo }
end

def skill_list(skills, low, high) 
    skills.
        select { |skill| skill.rating >= low && skill.rating <= high}.
        select { |skill| skill.rusty < 6 }.
        #sort { |x,y| x.rating == y.rating ? x.rusty <=> y.rusty : y.rating <=> x.rating}.
        sort { |x,y| y.rating - y.rusty <=> x.rating - x.rusty}.
        collect{|s| s.name }.join(", ")

end

def latex_desc(bla)
  bla.gsub(/%/, "\\%").gsub(/\&/, '\\\\&').gsub(/\$/, '\\\\$').gsub(/_/, '\\_').gsub(/#/,'\\#')
end

def trim_jobs(jobs, max_age=MAX_JOB_AGE) 
	jobs.select do |job|
		start_year = extract_year(job.start_time)
    end_year = extract_year(job.end_time)

		current_year = Time.new.year
		end_year == "Present" or current_year - end_year.to_i <= max_age
	end
end

def organize_publications(authored, edited)
  a2 = authored.map do |author|
   author["role"] = "Author"
   author["clout"] = 10
   author["author"] = nil
   author
  end

  e2 = edited.map do |editor|
   editor["role"] = "Technical Reviewer"
   editor
  end

  array = a2 + e2

  array.sort_by{|a| a["year"]}.reverse


end

def trim_by_clout(things, min_clout=5)
  things.select{|p| p.fetch("clout", 0) >= min_clout}
end

def trim_skills(skills, max_items=10)
  array = skills.split(/,\s*/).take(max_items)
  array[0..-2].join(", ") + ", and " + array[-1]
end


def trunc_jobs(jobs, max) 
  jobs.take(max)
end

def trim_accomplishments(accomplishments, index, maximum=MAX_ACCOMPLISHMENTS, minimum=MIN_ACCOMPLISHMENTS)
  if(index == 0)
    accomplishments
  else
    min = [maximum-index, minimum].max
    accomplishments[0..min-1]
  end
end