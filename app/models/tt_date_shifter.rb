class TtDateShifter
  attr_accessor :start_date, :stop_date, :last_start, :last_stop

  def initialize(args = {}, *arguments)
    self.last_start = args[:start_date].to_date
    self.last_stop = args[:stop_date].to_date
  end

  # returns the actual month
  def get_this_time_span
    self.start_date = Time.now.localtime.beginning_of_month.to_date
    self.stop_date = Time.now.localtime.end_of_month.to_date
  end

  def get_prev_time_span
    span = calc_time_span
    if span == "month"
      self.start_date = (last_start - 1.month).beginning_of_month
      self.stop_date = (last_stop - 1.month).end_of_month
    else # default is step a number of days
      self.start_date = last_start - span.days
      self.stop_date = last_stop - span.days
    end
  end

  def get_next_time_span
    span = calc_time_span
    if span == "month"
      self.start_date = (last_start + 1.month).beginning_of_month
      self.stop_date = (last_stop + 1.month).end_of_month
    else # default is step a number of days
      self.start_date = last_start + span.days
      self.stop_date = last_stop + span.days
    end
  end

  private

  # calculates the time_span between the given dates. we only differ "month" or "days". in case of month we can take
  # special advantage to the beginning and end of the month. if we use the days, the user can shift the dates using
  # the number of days as step-width
  def calc_time_span
    if self.last_start == self.last_start.beginning_of_month && self.last_stop == self.last_stop.end_of_month
      "month"
    else
      last_stop - last_start
    end
  end
end
