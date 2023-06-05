                  # language: pt

                  @teste
                  Funcionalidade: Abrir aplicativo do Google Chrome

                  Esquema do Cenário: Abrir o aplicativo do Google Chrome no dispositivo móvel e fazer uma pesquisa básica
                  Dado Que eu abra o aplicativo do Google Chrome no disposito móvel
                  Quando Eu aguarde o carregamento da página
                  Então Eu encontre "<elemento>"

                  Exemplos:
                  | elemento                                   |
                  | com.android.chrome:id/search_box_text      |
                  | com.android.chrome:id/voice_search_button  |
                  | com.android.chrome:id/tab_switcher_button  |
                  | com.android.chrome:id/batata               |
                  | com.android.chrome:id/search_provider_logo |
                  | com.android.chrome:id/menu_badge           |

