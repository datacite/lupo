class DataDumpsController < ApplicationController
  def index
  end

  def show
    data_dump = DataDump.where(uid: params[:id]).first
    if data_dump.blank? ||
      (
        data_dump.aasm_state != "complete"
        # TODO: Add conditional check for role here
      )
      fail ActiveRecord::RecordNotFound
    end
    render json: DataDumpSerializer.new(data_dump).serialized_json, status: :ok
  end
end
