Dado('Que eu abra o aplicativo do Google Chrome no disposito móvel') do
  start_activity(app_package: 'com.android.chrome', app_activity: 'com.google.android.apps.chrome.Main')
end

Quando('Eu aguarde o carregamento da página') do
  sleep 10
end

Então('Eu encontre {string}') do |elemento|
  find_element(:id, elemento).displayed?
end
