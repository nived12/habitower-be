# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      def index
        page = [params[:page].to_i, 1].max
        per_page = [params[:per_page].to_i, 1].max
        per_page = 20 if per_page.zero?
        per_page = [per_page, 100].min

        @notifications = current_user.notifications
          .includes(:actor, :notifiable)
          .order(created_at: :desc)
          .offset((page - 1) * per_page)
          .limit(per_page)
        @meta = {
          page: page,
          per_page: per_page,
          total: current_user.notifications.count
        }
      end

      def read
        notification = current_user.notifications.find(params[:id])
        notification.update!(read_at: Time.current)
        head(:ok)
      end

      def read_all
        current_user.notifications.unread.update_all(read_at: Time.current)
        head(:ok)
      end
    end
  end
end
