require_dependency 'issue'

module TtIssuePatch
  extend ActiveSupport::Concern

  included do
    class_eval do
      has_many :time_entries, :dependent => :destroy
    end
  end
end

Issue.send :include, TtIssuePatch
