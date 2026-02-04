# frozen_string_literal: true

module Api
  module V1
    class FollowsController < BaseController
      def index
        @users = current_user.followed_users
          .order("follows.created_at DESC")
      end

      def followers
        @users = current_user.follower_users
          .order("follows.created_at DESC")
      end

      def create
        followed = User.find(params[:followed_id])
        return render_error("422", "Cannot follow yourself", :unprocessable_content) if followed.id == current_user.id

        follow = current_user.following.build(followed: followed)
        if follow.save
          Notifications::Creator.call(
            recipient: followed,
            actor: current_user,
            action: "follow",
            notifiable: current_user,
            data: {}
          )
          @follow = follow
          render(:show, status: :created)
        else
          render_validation_errors(follow)
        end
      end

      def destroy
        follow = current_user.following.find(params[:id])
        follow.destroy
        head(:no_content)
      end
    end
  end
end
