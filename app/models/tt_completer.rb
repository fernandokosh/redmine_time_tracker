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
      issue_list += Issue.visible.where(["#{Issue.table_name}.id LIKE ?", "%#{term.downcase}%"]).all
    end
    unless term.blank?
      issue_list += Issue.visible.where(["LOWER(#{Issue.table_name}.subject) LIKE ?", "%#{term.downcase}%"]).all
    end
    issue_list.uniq! unless issue_list.empty?
    issue_list.compact!
    issue_list.delete_if do |issue|
      !help.permission_checker([:tt_book_time, :tt_edit_own_bookings, :tt_edit_bookings], help.project_from_id(issue.project_id)) || issue.closed?
    end
    issue_list.each do |issue|
      self.data.push({:label => "##{issue.id} #{issue.subject}", :value => "#{issue.id}", :data => "#{issue.subject}"})
    end
  end

  def to_json(options)
    self.data.to_json
  end
end
