class ServiceRecordsController < ApplicationController
  in_place_edit_for :session, :date
  in_place_edit_for :service_record, :ref_code
  in_place_edit_for :service_record, :quantity

  # GET /service_records/new
  def new
    @service_record = ServiceRecord.new
    @patient = Patient.find(params[:patient_id])
    @session = Session.find(params[:session_id])

    # Defaults
    @service_record.quantity = 1

    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.select('.new_session_service_record').each do |form|
            form.hide
          end
          page.show "new_session_#{@session.id}_service_record"
          page.replace_html "new_session_#{@session.id}_service_record", :partial => 'form'
        end
      }
    end
  end

  # POST /service_records
  def create
    tariff_item = TariffItem.find(params[:tariff_item_id])
    @patient = Patient.find(params[:patient_id])
    @session = Session.find(params[:session_id])

    service_record = @session.build_service_record(tariff_item)
    
    @session.save

    flash[:notice] = 'Erfolgreich erfasst.'

    respond_to do |format|
      format.html {
        redirect_to :controller => 'patients', :action => 'show', :id => @patient, :tab => 'services'
        return
      }
      format.js {
        render :update do |page|
          page.replace_html "session_#{@session.id}", :partial => 'sessions/item', :object => @session
          page.replace_html "treatment_service_list_total", "Total: #{'%0.2f' % @session.treatment.amount.currency_round}"
        end
      }
    end
  end

  # GET /service_records/select
  def select
    query = params[:query]
    query ||= params[:search][:query] if params[:search]

    @tariff_items = TariffItem.clever_find(query).paginate(:page => params['page'])
    @patient = Patient.find(params[:patient_id])
    @session = Session.find(params[:session_id])
    
    # Show selection list only if more than one hit
    if @tariff_items.size == 1
      params[:tariff_item_id] = @tariff_items.first.id
      create
      return
    end
      
    respond_to do |format|
      format.html { }
      format.js {
        render :update do |page|
          page.replace_html "session_#{@session.id}_search_results", :partial => 'select_list'
        end
      }
    end
  end

  # DELETE /service_record/1
  def destroy
    service_record = ServiceRecord.find(params[:id])
    @patient = Patient.find(params[:patient_id])
    @session = Session.find(params[:session_id])

    service_record.destroy
    
    respond_to do |format|
      format.html {
        redirect_to :controller => 'patients', :action => 'show', :id => @patient, :tab => 'services'
        return
      }
      format.js {
        render :update do |page|
          page.replace_html "session_#{@session.id}", :partial => 'sessions/item', :object => @session
          page.replace_html "treatment_service_list_total", "Total: #{@session.treatment.amount.currency_round}"
        end
      }
    end
  end
end
