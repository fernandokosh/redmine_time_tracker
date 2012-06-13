class TimeLogsController < ApplicationController
  unloadable

  before_filter :authorize_global

  def index
    user = User.current
    bookable_logs_temp = []
    user.time_logs.each do |tl|
      bookable_logs_temp.push(tl) if tl.bookable_hours > 0
    end
    # limit output of time_log list
    # we have to prepare some values so the classic-pagination can handle or array
    @unbooked_logs_count = bookable_logs_temp.count
    limit = 10
    params['page_unbooked'].to_i == 0 ? page = 1 : page = params['page_unbooked'].to_i
    @unbooked_logs_pages = Paginator.new self, @unbooked_logs_count, limit, page
    limit * (page - 1) > bookable_logs_temp.size - 1 ? offset = 0 : offset = limit * (page - 1)
    offset + limit >= bookable_logs_temp.size ? stop_loop = bookable_logs_temp.size-1 : stop_loop = offset + limit - 1
    # filling the array for the view
    @bookable_logs = []
    for i in offset..stop_loop
      @bookable_logs.push(bookable_logs_temp[i])
    end

    # time booking list
    user_bookings_temp = TimeBooking.get_bookings
    @user_bookings_count = user_bookings_temp.count
    limit1 = 10
    params['page_booked'].to_i == 0 ? page1 = 1 : page1 = params['page_booked'].to_i
    @booked_logs_pages = Paginator.new self, @user_bookings_count, limit1, page1
    limit1 * (page1 - 1) > user_bookings_temp.size - 1 ? offset1 = 0 : offset1 = limit1 * (page1 - 1)
    offset1 + limit1 >= user_bookings_temp.size ? stop_loop1 = user_bookings_temp.size-1 : stop_loop1 = offset1 + limit1 - 1
    # filling the array for the view
    @user_bookings = []
    for j in offset1..stop_loop1
      @user_bookings.push(user_bookings_temp[j])
    end
  end

  def add_booking
    issue = issue_from_id(params[:issue_id])
    if User.current.allowed_to?(:log_time, issue.project)
      time_log = TimeLog.where(:id => params[:time_log_id]).first
      time_log.add_booking(:hours => params[:hours], :comments => params[:comments], :issue => issue)
      redirect_to '/time_logs'
    else
      flash[:error] = "not allowed to do that.. :)"
      redirect_to '/time_logs'
    end
  end

  def show_booking
    @time_log = TimeLog.where(:id => params[:time_log_id]).first
    render :partial => 'booking_form'
  end

  private

  # TODO move this function into a helper due to DRY
  def issue_from_id(issue_id)
    Issue.where(:id => issue_id).first
  end
end