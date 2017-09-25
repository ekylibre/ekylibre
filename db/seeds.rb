Tour.destroy_all

# English tour for welcome page
Tour.create(page: "home", language: "eng", position: "home", title: "Welcome on Ekylibre", content: "We will make a quick tour of the interface of the application. First this button permits to go home from anywhere in application.")
Tour.create(page: "home", language: "eng", position: "parts", title: "Modules of Ekylibre", content: "This menu permits to access to all of main modules.")
Tour.create(page: "home", language: "eng", position: "user", title: "User menu", content: "Here, you can see your notifications, show help, read your farm name. Your user preferences are editable from menu.")
Tour.create(page: "home", language: "eng", position: "side", title: "Module side bar", content: "This side bar contains all the sub-menus of the current module you are consulting.")
Tour.create(page: "home", language: "eng", position: "main", title: "Where you work", content: "Where all the action take place is here. We wish you an happy usage.")
# English tour for production page
Tour.create(page: "production", language: "eng", position: "production", title: "Production", content: "Activities permits to define what you want to produce and plan it.")
Tour.create(page: "production", language: "eng", position: "quality", title: "Quality tools", content: "Follow your crops and activities with many types of analyses, monitor diseases with issues and check harvest quality with inspections.")
Tour.create(page: "production", language: "eng", position: "field_distribution", title: "Fields", content: "Find here the 3 levels for cultivations: cultivable zones (independent of campaigns), land parcels defined in productions, and cultivations sowed during interventions.")
Tour.create(page: "production", language: "eng", position: "supervision", title: "Sensors", content: "Sensors permits to register and concentrate values of yours sensors in your fields.")

# French tour for welcome page
Tour.create(page: "home", language: "fra", position: "home", title: "Bienvenue sur Ekylibre", content: "Nous allons faire un tour rapide de l’interface de l’application. Tout d’abord ce bouton permet de revenir à l’accueil depuis n’importe où dans l’application.")
Tour.create(page: "home", language: "fra", position: "parts", title: "Modules de Ekylibre", content: "Ce menu permet d’accéder à l’ensemble des modules principaux.")
Tour.create(page: "home", language: "fra", position: "user", title: "Menu utilisateur", content: "Ici, vous pouvez voir vos notifications, afficher l’aide, lire le nom de votre ferme. Vos préférences utilisateur sont modifiables à partir du menu aussi.")
Tour.create(page: "home", language: "fra", position: "side", title: "Barre latérale du module", content: "Cette barre latérale contient tous les sous-menus du module où vous vous trouvez.")
Tour.create(page: "home", language: "fra", position: "main", title: "Où vous travaillez", content: "Toute l’action prend place ici. Nous vous souhaitons une bonne prise en main.")
#French tour for production page
Tour.create(page: "production", language: "fra", position: "production", title: "Production", content: "Les activités permettent de définir ce que vous voulez produire et le planifier.")
Tour.create(page: "production", language: "fra", position: "quality", title: "Outils pour la qualité", content: "Suivez vos cultures et les activités avec différents types d’analyses, les maladies en enregistrant les incidents et vérifiez la qualité de la récolte avec des agréages.")
Tour.create(page: "production", language: "fra", position: "field_distribution", title: "Parcellaire", content: "Trouvez ici les 3 niveaux pour les cultures\_: zones cultivables (indépendantes des campagnes), les parcelles définies dans les productions et les cultures semées au cours des interventions.")
Tour.create(page: "production", language: "fra", position: "supervision", title: "Capteurs", content: "Enregistrez et regroupez les valeurs remontées de vos capteurs dans vos champs ici.")

# Arabic tour for welcome page
Tour.create(page: "home", language: "arb", position: "home", title: "مرحبا بكم في Ekylibre", content: "سنقوم بعمل جولة سريعة من واجهة التطبيق. أول هذه التصاريح زر العودة إلى المنزل من أي مكان في التطبيق.")
Tour.create(page: "home", language: "arb", position: "parts", title: "وحدات من Ekylibre", content: "تسمح هذه القائمة إلى الوصول إلى جميع وحدات رئيسية.")
Tour.create(page: "home", language: "arb", position: "user", title: "القائمة المستخدم", content: "هنا، يمكنك أن ترى الإشعارات، وتبين مساعدة، وقراءة اسم المزارع الخاصة بك. تفضيلات المستخدم الخاص بك للتحرير من القائمة.")
Tour.create(page: "home", language: "arb", position: "side", title: "الشريط الجانبي وحدة", content: "يحتوي هذا الشريط الجانبي جميع القوائم الفرعية وحدة الحالية التي يجري التشاور.")
Tour.create(page: "home", language: "arb", position: "main", title: "اين تعمل", content: "حيث كل مكان اتخاذ الإجراءات هنا. نتمنى لك استخدام سعيدا.")
#Arabic tour for production page
Tour.create(page: "production", language: "arb", position: "production", title: "إنتاج", content: "تسمح الأنشطة لتحديد ما تريد لإنتاج والتخطيط له.")
Tour.create(page: "production", language: "arb", position: "quality", title: "أدوات الجودة", content: "اتبع المحاصيل والأنشطة الخاصة بك مع العديد من أنواع التحليلات، ومراقبة الأمراض مع القضايا والتحقق من جودة الحصاد مع عمليات التفتيش.")
Tour.create(page: "production", language: "arb", position: "field_distribution", title: "مجالات", content: "تجد هنا 3 مستويات للالزراعات: مناطق صالحة للزراعة (مستقلة من الحملات)، قطع الأراضي المحددة في الإنتاج، والزراعات زرعت خلال التدخلات.")
Tour.create(page: "production", language: "arb", position: "supervision", title: "أجهزة الاستشعار", content: "تصاريح أجهزة استشعار لتسجيل والتركيز القيم لك أجهزة الاستشعار في الحقول.")

#Mandarin chinese tour for welcome page
Tour.create(page: "home", language: "cmn", position: "home", title: "欢迎Ekylibre", content: "我们将应用程序的界面的快速浏览。首先这个按钮允许从应用程序中的任何地方回家。")
Tour.create(page: "home", language: "cmn", position: "parts", title: "Ekylibre的模块", content: "此菜单允许访问所有主要模块。")
Tour.create(page: "home", language: "cmn", position: "user", title: "用户菜单", content: "在这里，您可以看到您的通知，显示帮助，请阅读你的农场名称。您的用户偏好，从菜单中编辑。")
Tour.create(page: "home", language: "cmn", position: "side", title: "模块侧栏", content: "该边栏包含要咨询当前模块的所有子菜单。")
Tour.create(page: "home", language: "cmn", position: "main", title: "你在哪里工作", content: "其中，所有的操作发生的位置就在这里。我们希望您的快乐使用。")
#Mandarin chinese tour for production page
Tour.create(page: "production", language: "cmn", position: "production", title: "生产", content: "活动允许定义要生产，并计划它是什么。")
Tour.create(page: "production", language: "cmn", position: "quality", title: "质量工具", content: "按照你的作物和活动，许多类型的分析，监测与疾病问题，检查收获质量检查。")
Tour.create(page: "production", language: "cmn", position: "field_distribution", title: "字段", content: "在这里查找栽培的3个层次：耕种区域（独立运动），在生产中定义地块，和干预措施期间播种栽培。")
Tour.create(page: "production", language: "cmn", position: "supervision", title: "传感器", content: "传感器许可登记并在您的领域集中你的传感器值。")

#Deutsch tour for welcome page
Tour.create(page: "home", language: "deu", position: "home", title: "Willkommen auf Ekylibre", content: "Wir werden eine kurze Tour durch die Schnittstelle der Anwendung machen. Zuerst diese Taste ermöglicht von überall in der Anwendung nach Hause zu gehen.")
Tour.create(page: "home", language: "deu", position: "parts", title: "Module von Ekylibre", content: "Dieses Menü erlaubt den Zugriff auf alle Hauptmodule.")
Tour.create(page: "home", language: "deu", position: "user", title: "Benutzermenü", content: "Hier können Sie Ihre Benachrichtigungen sehen, Hilfe, lesen Sie Ihre Farmnamen. Ihre Benutzereinstellungen sind editierbar aus dem Menü.")
Tour.create(page: "home", language: "deu", position: "side", title: "Modulseitenleiste", content: "Diese Seite Leiste enthält alle Untermenüs des aktuellen Moduls Sie beraten.")
Tour.create(page: "home", language: "deu", position: "main", title: "Wo Du arbeitest", content: "Wo die Action stattfinden ist hier. Wir wünschen Ihnen einen angenehmen Gebrauch.")
#Deutsch tour for production page
Tour.create(page: "production", language: "deu", position: "production", title: "Produktion", content: "Aktivitäten erlaubt zu definieren, was Sie wollen, es zu produzieren und zu planen.")
Tour.create(page: "production", language: "deu", position: "quality", title: "Qualitätswerkzeuge", content: "Folgen Sie Ihre Pflanzen und Aktivitäten mit vielen Arten von Analysen, überwachen Krankheiten, die mit Fragen und überprüfen Erntequalität mit Inspektionen.")
Tour.create(page: "production", language: "deu", position: "field_distribution", title: "Felder", content: "Hier finden Sie die 3 Ebenen für Anpflanzungen: bebaubar Zonen (unabhängig von Kampagnen), Landparzellen in Produktionen definiert und Anpflanzungen bei Eingriffen säte.")
Tour.create(page: "production", language: "deu", position: "supervision", title: "Sensoren", content: "Sensoren erlaubt zu registrieren und Werte von Ihnen Sensoren in Ihre Felder konzentrieren.")

#Italian tour for welcome page
Tour.create(page: "home", language: "ita", position: "home", title: "Benvenuti su Ekylibre", content: "Faremo un breve tour della interfaccia dell’applicazione. In primo luogo questo tasto permette di tornare a casa da qualsiasi applicazione.")
Tour.create(page: "home", language: "ita", position: "parts", title: "Moduli di Ekylibre", content: "Questo menu permette di accedere a tutti i moduli principali.")
Tour.create(page: "home", language: "ita", position: "user", title: "Menu utente", content: "Qui, è possibile vedere le notifiche, mostrare aiuto, leggere il tuo nome farm. Le preferenze degli utenti sono modificabili dal menu.")
Tour.create(page: "home", language: "ita", position: "side", title: "Barra laterale modulo", content: "Questa barra laterale contiene tutti i sottomenu del modulo attuale si sta consultando.")
Tour.create(page: "home", language: "ita", position: "main", title: "Dove lavori", content: "Dove tutte le azioni si svolgono è qui. Vi auguriamo un uso felice.")
#Italian tour for production page
Tour.create(page: "production", language: "ita", position: "production", title: "Produzione", content: "Attività permette di definire ciò che si vuole produrre e pianificare.")
Tour.create(page: "production", language: "ita", position: "quality", title: "Strumenti di qualità", content: "Seguire il tuo colture e le attività con molti tipi di analisi, monitorare le malattie con problemi e verificare la qualità del raccolto con le ispezioni.")
Tour.create(page: "production", language: "ita", position: "field_distribution", title: "Campi", content: "Trova qui i 3 livelli di coltivazioni: zone coltivabili (indipendenti di campagne), appezzamenti definiti in produzioni e coltivazioni seminati durante gli interventi.")
Tour.create(page: "production", language: "ita", position: "supervision", title: "Sensori", content: "Sensori permette di registrare e concentrarsi valori dei sensori vostro in campi.")

#Japanese tour for welcome page
Tour.create(page: "home", language: "jpn", position: "home", title: "Ekylibreにようこそ", content: "私たちは、アプリケーションのインターフェイスのクイックツアーを行います。アプリケーションのどこからでも家に帰るまずこのボタンを可能にします。")
Tour.create(page: "home", language: "jpn", position: "parts", title: "Ekylibreのモジュール", content: "このメニューは、メインモジュールのすべてにアクセスすることを許可します。")
Tour.create(page: "home", language: "jpn", position: "user", title: "ユーザメニュー", content: "ここで、あなたは、あなたの通知を参照してくださいヘルプを表示、ファーム名を読み取ることができます。ユーザー設定は、メニューから編集可能です。")
Tour.create(page: "home", language: "jpn", position: "side", title: "モジュールのサイドバー", content: "このサイドバーには、相談している現在のモジュールのすべてのサブメニューが含まれています。")
Tour.create(page: "home", language: "jpn", position: "main", title: "どこで働きます", content: "すべてのアクションが起こるのはここです。私たちはあなたに幸せな利用を望みます。")
#Japanese tour for production page
Tour.create(page: "production", language: "jpn", position: "production", title: "製造", content: "活動は、あなたが生産し、それを計画したいのかを定義することを可能にします。")
Tour.create(page: "production", language: "jpn", position: "quality", title: "品質ツール", content: "、分析の多くの種類のあなたの作物や活動に従って問題に疾患を監視し、検査と収穫の品質をチェック。")
Tour.create(page: "production", language: "jpn", position: "field_distribution", title: "フィールズ", content: "耕作ゾーン（キャンペーンの独立した）、制作に定義された土地区画、および介入中に播種栽培：栽培のための3つのレベルをここで見つけます。")
Tour.create(page: "production", language: "jpn", position: "supervision", title: "センサー", content: "センサーは、あなたの分野であなたセンサーの値を登録し、集中することを可能にします。")

#Portugese tour for welcome page
Tour.create(page: "home", language: "por", position: "home", title: "Bem-vindo a Ekylibre", content: "Vamos fazer uma visita rápida da interface da aplicação. Em primeiro lugar este botão permite ir para casa a partir de qualquer lugar no aplicativo.")
Tour.create(page: "home", language: "por", position: "parts", title: "Módulos de Ekylibre", content: "Este menu permite acesso a todos os módulos principais.")
Tour.create(page: "home", language: "por", position: "user", title: "Menu do usuário", content: "Aqui, você pode ver as suas notificações, mostrar ajuda, leia o seu nome da fazenda. Suas preferências de usuário são editáveis a partir do menu.")
Tour.create(page: "home", language: "por", position: "side", title: "Barra lateral Módulo", content: "Esta barra lateral contém todos os sub-menus do módulo atual que você está consultando.")
Tour.create(page: "home", language: "por", position: "main", title: "Onde você trabalha", content: "Onde toda a ação ocorra é aqui. Desejamos-lhe um uso feliz.")
#Portugese tour for production page
Tour.create(page: "production", language: "por", position: "production", title: "Produção", content: "Atividades permite definir o que você quer produzir e planejar.")
Tour.create(page: "production", language: "por", position: "quality", title: "Ferramentas de qualidade", content: "Siga as suas culturas e atividades com muitos tipos de análises, controlar doenças com problemas e verificar a qualidade da colheita com inspeções.")
Tour.create(page: "production", language: "por", position: "field_distribution", title: "Campos", content: "Encontre aqui os 3 níveis para cultivos: zonas cultiváveis ​​(independentes de campanhas), parcelas de terra definidas nas produções e culturas semeadas durante as intervenções.")
Tour.create(page: "production", language: "por", position: "supervision", title: "Sensores", content: "Sensores de licenças para registrar e concentrar-se valores de sensores seu em seus campos.")

#Spanish tour for welcome page
Tour.create(page: "home", language: "spa", position: "home", title: "Bienvenido a Ekylibre", content: "Vamos a hacer una visita rápida de la interfaz de la aplicación. En primer lugar este botón permisos para ir a casa desde cualquier lugar de la aplicación.")
Tour.create(page: "home", language: "spa", position: "parts", title: "Módulos de Ekylibre", content: "Este menú permite acceder a todos los módulos principales.")
Tour.create(page: "home", language: "spa", position: "user", title: "Menú del Usuario", content: "Aquí, se puede ver sus notificaciones, mostrar ayuda, leer su nombre de la granja. Sus preferencias del usuario se pueden modificar desde el menú.")
Tour.create(page: "home", language: "spa", position: "side", title: "Barra lateral del módulo", content: "Esta barra lateral contiene todos los submenús del módulo actual que está consultando.")
Tour.create(page: "home", language: "spa", position: "main", title: "Donde trabajas", content: "Donde toda la acción tendrá lugar está aquí. Le deseamos un uso feliz.")
#Spanish tour for production page
Tour.create(page: "production", language: "spa", position: "production", title: "Producción", content: "Actividades permite definir lo que se quiere producir y planificarlo.")
Tour.create(page: "production", language: "spa", position: "quality", title: "Herramientas de calidad", content: "Siga sus cultivos y actividades con muchos tipos de análisis, seguimiento de las enfermedades con problemas y comprobar la calidad de la cosecha con las inspecciones.")
Tour.create(page: "production", language: "spa", position: "field_distribution", title: "Campos", content: "Encuentra aquí los 3 niveles para cultivos: zonas cultivables (independientes de las campañas), las parcelas definidas en las producciones y cultivos sembrados durante las intervenciones.")
Tour.create(page: "production", language: "spa", position: "supervision", title: "Sensores", content: "Sensores permite que se registren y se concentran los valores de los sensores de la suya en sus campos.")