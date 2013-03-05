def display_schoolyear(time)
  endyear = time.match(/\d+-(\d+)/)[1].to_i
  ( (endyear > Time.new.year) ? "Anticipated " : "") + endyear.to_s
end

def skill_list(skills, low, high) 
    skills.
        select { |skill| skill.rating >= low && skill.rating <= high}.
        select { |skill| skill.rusty < 6 }.
        sort { |x,y| x.rusty <=> y.rusty }.
        collect{|s| s.name}.join(", ")

end