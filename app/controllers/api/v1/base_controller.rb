# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Pundit::Authorization
      include ErrorHandler

      before_action :authenticate_user!
    end
  end
end
