MAX_JOB_AGE=10
MAX_ACCOMPLISHMENTS=4

def display_schoolyear(degree, expand_school_flag= false, before = "(", after=")") 
  endyear = degree.time.match(/\d+-(\d+)/)[1].to_i
  if(endyear > Time.new.year) 
  	"#{before}E.G.D. #{endyear}#{after}"
  elsif(expand_school_flag)
  	"#{before}#{endyear}#{after}"
  else
  	""
  end
end

def unique_skills(skills)
	skills.sort_by{|s| s["rating"] }.reverse.inject([]) { |memo,x| memo << x unless memo.detect { |item| item["name"] == x["name"] }; memo }
end

def skill_list(skills, low, high) 
    skills.
        select { |skill| skill.rating >= low && skill.rating <= high}.
        select { |skill| skill.rusty < 6 }.
        sort { |x,y| x.rating == y.rating ? x.rusty <=> y.rusty : y.rating <=> x.rating}.
        collect{|s| s.name }.join(", ")

end

def trim_jobs(jobs) 
	jobs.select do |job|
		start_year, end_year = job.time.split("-")
		current_year = Time.new.year
		end_year == "Present" or current_year - end_year.to_i < MAX_JOB_AGE
	end
end

def trim_accomplishments(accomplishments)
  accomplishments[0..MAX_ACCOMPLISHMENTS-1]
end