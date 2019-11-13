class RecordsController < ApplicationController

  before_action :check_admin, except: [:update_all_record_values]
  before_action :set_record, only: [:edit, :update, :destroy, :delete]

  def index
    @records = Record.all.limit(500).order('updated_at desc')
  end

  def new
    @record = Record.new
  end

  def edit
  end

  def create
    @record = Record.new(record_params)
    if @record.save
      put_notice t(:record_created_ok)
      go_records
    else
      render :new
    end
  end

  def update
    if @record.update(record_params)
      put_notice t(:record_updated_ok)
      go_records
    else
      render :edit
    end
  end

  def destroy
    @record.destroy
    put_notice t(:record_destroyed_ok)
    go_records
  end

  def delete
    destroy
  end

  private

    def set_record
      @record = Record.find(params[:id])
    end

    def record_params
      params.require(:record).permit(:class_name, :oid, :value)
    end

end
