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

def job_field(job, key)
  if job.respond_to?(key)
    job.public_send(key)
  elsif job.is_a?(Hash)
    job[key] || job[key.to_s] || job[key.to_sym]
  else
    nil
  end
end

def years_for_job(job)
  current_year = Time.new.year

  year_val = job_field(job, :year)
  if !year_val.nil? && !year_val.to_s.strip.empty?
    y = extract_year(year_val).to_s.strip
    y = current_year.to_s if y == "Present"
    return [y.to_i]
  end

  start_val = job_field(job, :start_time)
  end_val   = job_field(job, :end_time)

  start_year_s = extract_year(start_val).to_s.strip
  end_year_s   = extract_year(end_val).to_s.strip
  end_year_s = current_year.to_s if end_year_s == "Present"

  start_year = start_year_s.to_i
  end_year   = end_year_s.to_i

  if start_year == 0 || end_year == 0
    raise ArgumentError,
          "Job missing valid year info: start=#{start_val.inspect} end=#{end_val.inspect} year=#{year_val.inspect} job=#{job.inspect}"
  end

  end_year = start_year if end_year < start_year
  (start_year..end_year).to_a
end

# Returns:
#   - Array of [skill_name, weight] sorted by weight descending
#
# Weight model:
#   For each (job, year, skill_position):
#     contribution = O(position) * Y(year)
#   where:
#     O(i) = (1 - order_decay)^i, with i=0 for first skill
#     Y(y) = (1 - yearly_decay)^(current_year - y)
#   Then:
#     W(skill) = sum(contribution over all occurrences)
#
# Cutoff:
#   If (current_year - last_used_year(skill)) >= year_cutoff, the skill is dropped entirely.
def calculate_skill_weights(jobs, order_decay = SKILL_ORDER_DECAY, yearly_decay = SKILL_YEARLY_DECAY, year_cutoff = YEAR_CUTOFF)
  current_year = Time.new.year

  normalize = lambda do |s|
    s.to_s.strip.gsub(/\s+/, " ")
  end

  weights = Hash.new(0.0)
  last_used = Hash.new { |h, k| h[k] = -1 }  # default: unknown/ancient

  jobs.each do |job|
    techs = job_field(job, :technologies)
    next if techs.nil? || techs.to_s.strip.empty?

    skill_list = techs.split(/,/).map { |s| normalize.call(s) }.reject(&:empty?)
    years = years_for_job(job)

    years.each do |year|
      year_age = current_year - year
      year_factor = (1.0 - yearly_decay) ** year_age

      skill_list.each_with_index do |skill, i|
        order_factor = (1.0 - order_decay) ** i
        weights[skill] += order_factor * year_factor
        last_used[skill] = year if year > last_used[skill]
      end
    end
  end

  # Drop anything older than the cutoff. If last_used is -1, drop it.
  weights.delete_if do |skill, _|
    lu = last_used[skill]
    lu < 0 || (current_year - lu) >= year_cutoff
  end

  weights.map { |skill, w| [skill, w] }.sort_by { |(_, w)| -w }
end


# Input:
#   skill_weights: Array of [skill_name, weight]
#
# Output:
#   { accomplished: [...], advanced: [...], novice: [...] }
# where each value is an array of skill names sorted by weight desc.
def group_by_level(skill_weights, max=13)
  counts = {}
  skill_weights.each do |skill, weight|
    counts[skill] = weight.to_f
  end

  return { accomplished: [], advanced: [], novice: [] } if counts.empty?

  values = counts.values
  mean = values.sum / values.size.to_f

  std_dev =
    if values.size <= 1
      0.0
    else
      var_sum = values.inject(0.0) { |acc, v| acc + (v - mean) ** 2 }
      variance = var_sum / (values.size - 1).to_f
      Math.sqrt(variance)
    end

  hi = mean + std_dev / 2.0
  lo = mean - std_dev / 2.0

  accomplished = counts.select { |_, v| v >= hi }
  advanced     = counts.select { |_, v| v < hi && v >= lo }
  novice       = counts.select { |_, v| v < lo }

  to_sorted_list = lambda do |h|
    h.sort_by { |(_, v)| -v }.map { |(k, _)| k }.take(max)
  end

  {
    accomplished: to_sorted_list.call(accomplished),
    advanced:     to_sorted_list.call(advanced),
    novice:       to_sorted_list.call(novice)
  }
end
# Input:
#   skill_weights: Array of [skill_name, weight] sorted by weight descending
#   skills_index:  Array of {"name"=>..., "category"=>...} (or symbol keys)
#   max:           Maximum number of skills to include per category
#
# Output:
#   Hash: { "Category" => [skill_name, ...], ... }
#
# Ordering:
#   - Preserves the incoming order from skill_weights globally
#   - Preserves first-seen order within each category
#
# Failure:
#   - Collects all missing skills and aborts once at the end
# Returns an ordered list (Array) rather than a Hash, preserving the category order
# defined in skills_index.
#
# Output shape:
#   [
#     ["Languages", ["Java", "Scala", ...]],
#     ["Web", ["Rails", "REST", ...]],
#     ...
#   ]
#
# Categories with no selected skills are omitted.
def group_by_category(skill_weights, skills_index, max = 13)
  normalize = ->(s) { s.to_s.strip }

  unless skills_index.is_a?(Hash)
    raise ArgumentError, "Expected skills_index to be a Hash of category => [skills], got #{skills_index.class}"
  end

  # Build lookup: normalized_skill_name -> category (category string preserved as in YAML)
  index = {}
  skills_index.each do |category, skills|
    next if skills.nil?
    unless skills.is_a?(Array)
      raise ArgumentError, "Expected skills_index[#{category.inspect}] to be an Array, got #{skills.class}"
    end

    skills.each do |entry|
      next unless entry.is_a?(Hash)
      name = entry[:name] || entry["name"]
      next if name.nil?

      key = normalize.call(name)
      next if key.empty?

      index[key] = category.to_s
    end
  end

  # Accumulate selections, but keep them keyed by category while we build.
  selected = {}
  seen_in_category = Hash.new { |h, k| h[k] = {} }
  missing = {} # preserves insertion order

  skill_weights.each do |skill, _weight|
    s = normalize.call(skill)
    next if s.empty?

    category = index[s]
    if category.nil? || category.to_s.strip.empty?
      missing[s] = true
      next
    end

    selected[category] ||= []
    next if selected[category].length >= max

    unless seen_in_category[category].key?(s)
      selected[category] << s
      seen_in_category[category][s] = true
    end
  end

  if missing.any?
    abort("Missing skills in skills_index (#{missing.size}): #{missing.keys.join(', ')}")
  end

  # Emit in the category order defined by skills_index
  ordered = []
  skills_index.each_key do |category|
    skills = selected[category.to_s]
    next if skills.nil? || skills.empty?
    ordered << [category.to_s, skills]
  end

  ordered
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

def skill_to_icons(skillname, skills_index)
  name = skillname.to_s.strip
  down = name.downcase

  if skills_index.is_a?(Hash)
    skills_index.each do |_category, skills|
      next unless skills.is_a?(Array)

      skills.each do |entry|
        next unless entry.is_a?(Hash)

        entry_name = entry[:name] || entry["name"]
        next if entry_name.nil?

        if entry_name.to_s.strip.downcase == down
          icons = entry[:icons] || entry["icons"]
          if icons && icons.respond_to?(:any?) && icons.any?
            return icons.map { |i| i.to_s }
          end
          return [down]
        end
      end
    end
  end

  [down]
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
  # if(index == 0)
  #   accomplishments
  # else
    min = [maximum-index, minimum].max
    accomplishments[0..min-1]
  # end
end