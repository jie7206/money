class RecordsController < ApplicationController

  before_action :check_admin
  before_action :set_record, only: [:show, :edit, :update, :destroy]

  def index
    @records = Record.all.limit(500).order('updated_at desc')
  end

  def show
  end

  def new
    @record = Record.new
  end

  def edit
  end

  def create
    @record = Record.new(record_params)
    if @record.save
      put_notice 'Record was successfully created.'
      go_records
    else
      render :new
    end
  end

  def update
    if @record.update(record_params)
      put_notice 'Record was successfully updated.'
      go_records
    else
      render :edit
    end
  end

  def destroy
    @record.destroy
    put_notice 'Record was successfully destroyed.'
    go_records
  end

  private

    def set_record
      @record = Record.find(params[:id])
    end

    def record_params
      params.require(:record).permit(:class_name, :oid, :value)
    end

end
