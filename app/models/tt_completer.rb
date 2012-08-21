class TtCompleter
  attr_accessor :query, :suggestions, :data

  def initialize(args = {}, *arguments)
    self.query = args[:query]
    self.suggestions = Array.new
    self.data = Array.new
  end

  def get_issue
    issue_list = Array.new
    if query.match(/^\d+$/)
      issue_list << Issue.visible.find_by_id(query.to_i)
    end
    unless query.blank?
      issue_list += Issue.visible.where(["LOWER(#{Issue.table_name}.subject) LIKE ?", "%#{query.downcase}%"]).limit(10).all
    end
    issue_list.compact!
    issue_list.each do |item|
      self.suggestions.push("##{item.id} #{item.subject}")
      self.data.push([item.id.to_s, item.subject])
    end
  end
end
