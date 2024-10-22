# frozen_string_literal: true

module ApiResponseWrapperConcern
  extend ActiveSupport::Concern

  def render_success(data, status = :ok)
    render json: { data: data }, status: status
  end

  def render_error(message, status: :unprocessable_entity)
    render json: { error: { message: message } }, status: status
  end

  def render_api_response(result, _status)
    if result.is_a?(ActiveRecord::RecordNotFound)
      render_error(result.message, status: :not_found)
    elsif result.is_a?(StandardError)
      Rails.logger.error("Unexpected error: #{result.message}")
      Rails.logger.error(result.backtrace&.join("\n"))
      render_error(result.message, status: :internal_server_error)
    else
      render_success(result, :ok)
    end
  end
end
