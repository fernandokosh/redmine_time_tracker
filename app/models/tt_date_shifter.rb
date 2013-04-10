class TtDateShifter
  attr_accessor :start_date, :stop_date, :last_start, :last_stop, :op, :special

  def initialize(args = {}, *arguments)
    if args[:start_date].blank?
      self.last_start =
          case args[:op]
            when "thisWeek"
              Time.now.localtime.to_date.beginning_of_week
            when "thisMonth"
              Time.now.localtime.to_date.beginning_of_month
            else
              # default is today
              Time.now.localtime.to_date
          end
    else
      self.last_start = args[:start_date].to_date
    end

    if args[:stop_date].blank?
      self.last_stop =
          case args[:op]
            when "thisWeek"
              Time.now.localtime.to_date.end_of_week
            when "thisMonth"
              Time.now.localtime.to_date.end_of_month
            else
              # default is today
              Time.now.localtime.to_date
          end
    else
      self.last_stop = args[:stop_date].to_date
    end

    self.op = args[:op]
  end

  def get_prev_time_span
    case span
      when "day"
        self.start_date = last_start - 1.day
        self.stop_date = last_start - 1.day
      when "week"
        self.start_date = (last_start - 1.week).beginning_of_week
        self.stop_date = (last_stop - 1.week).end_of_week
      when "month"
        self.start_date = (last_start - 1.month).beginning_of_month
        self.stop_date = (last_stop - 1.month).end_of_month
      else # default is step a number of days
        self.start_date = last_start - span.days
        self.stop_date = last_stop - span.days
    end
    check_special
  end

  def get_next_time_span
    case span
      when "day"
        self.start_date = last_start + 1.day
        self.stop_date = last_start + 1.day
      when "week"
        self.start_date = (last_start + 1.week).beginning_of_week
        self.stop_date = (last_stop + 1.week).end_of_week
      when "month"
        self.start_date = (last_start + 1.month).beginning_of_month
        self.stop_date = (last_stop + 1.month).end_of_month
      else # default is step a number of days
        self.start_date = last_start + span.days
        self.stop_date = last_stop + span.days
    end
    check_special
  end

  private

  # calculates the time_span between the given dates. we only differ "month", "week" or "days". in case of month and week
  # we can take special advantage to the beginning and end of the month/week. if we use the days, the user can shift
  # the dates using the number of days as step-width
  def span
    if op == "is" || op == "today"
      "day"
    elsif op == "thisWeek" || op == "between" && self.last_start == self.last_start.beginning_of_week && self.last_stop == self.last_stop.end_of_week
      "week"
    elsif op == "thisMonth" || op == "between" && self.last_start == self.last_start.beginning_of_month && self.last_stop == self.last_stop.end_of_month
      "month"
    else
      last_stop - last_start + 1
    end
  end

  def check_special
    self.special = ""
    self.special = "today" if start_date == Time.now.localtime.to_date && stop_date == Time.now.localtime.to_date
    self.special = "thisWeek" if start_date == Time.now.localtime.to_date.beginning_of_week && stop_date == Time.now.localtime.to_date.end_of_week
    self.special = "thisMonth" if start_date == Time.now.localtime.to_date.beginning_of_month && stop_date == Time.now.localtime.to_date.end_of_month
  end
end