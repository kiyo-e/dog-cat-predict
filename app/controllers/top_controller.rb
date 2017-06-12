class TopController < ApplicationController
  def index
    @form = PredictForm.new
  end

  def predict
    @form = PredictForm.new(predict_form_params)
    @form.predict
    render
  end

  private
  def predict_form_params
    params.require(:predict_form).permit(
      :file
    )
  end
end
