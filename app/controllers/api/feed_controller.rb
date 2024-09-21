class Api::FeedController < ApplicationController
  def index
    @activity_logs = Activity.logs_for(@logged_user.projects.all.to_a, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
    render json: { activity_logs: @activity_logs }, status: :ok
  end
end
