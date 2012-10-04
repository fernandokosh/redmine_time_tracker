class TtCompleter
  attr_accessor :term, :data, :label, :value

  def initialize(args = {}, *arguments)
    self.term = args[:term]
    self.data = Array.new
  end

  def get_issue(flag = 0)
    issue_list = Array.new
    if term.match(/^\d+$/)
      issue_list << Issue.visible.find_by_id(term.to_i)
    end
    unless term.blank?
      issue_list += Issue.visible.where(["LOWER(#{Issue.table_name}.subject) LIKE ?", "%#{term.downcase}%"]).limit(10).all
    end
    issue_list.compact!
    issue_list.each do |item|
      self.data.push({:label => "##{item.id} #{item.subject}", :value => "#{item.id}", :data => "#{item.subject}"})
    end
  end
  
  def to_json(options)
    self.data.to_json
  end
end
