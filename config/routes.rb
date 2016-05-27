QualityMeter::Engine.routes.draw do
  get 'qmeter' => 'quality_meter/report#index'
  get 'qmeter/js_cs' => 'quality_meter/report#js_cs'
end
