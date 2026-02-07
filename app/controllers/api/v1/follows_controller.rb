# frozen_string_literal: true

module Api
  module V1
    class FollowsController < BaseController
      # GET /api/v1/me/following
      def index
        @users = current_user.followed_users.order("follows.created_at DESC")
      end

      # GET /api/v1/me/followers
      def followers
        @users = current_user.follower_users.order("follows.created_at DESC")
      end

      # POST /api/v1/follows
      def create
        followed = User.find(params[:followed_id])
        return render_error("422", "Cannot follow yourself", :unprocessable_content) if followed.id == current_user.id

        @follow = current_user.following.build(followed: followed)
        if @follow.save
          begin
            Notification.create!(
              recipient: followed,
              actor: current_user,
              action: "follow",
              notifiable: current_user
            )
          rescue StandardError => e
            Rails.logger.warn("Follow notification failed for follow #{@follow.id}: #{e.message}")
          end
          render(:show, status: :created)
        else
          render_validation_errors(follow)
        end
      end

      # DELETE /api/v1/follows/:id
      def destroy
        current_user.following.find(params[:id]).destroy
        head(:no_content)
      end
    end
  end
end
