# MiniDiscord

## Phase 1

Q1) Process.monitor(pid) permet au serveur d'être informé lorsqu'un client se déconnecte (crash, fermeture, etc.) ainsi les liste des clients connecté est quand même mise à jour si le client se déconnecte sans en informer volontairement le serveur.

Q2) Cela permet de traiter le message :DOWN lorsqu'il est envoyé par un client afin d'éviter de lui envoyer les messages alors qu'il est déconnecté.

Q3) handle_call : Synchrone, attend une réponse et monopolise la connexion avec le client tant qu'il n'a pas reçu de réponse.
    handle_cast : Asynchrone, aucune réponse attendue et ne monopolise pas la connexion.

broadcast est un cast car il a comme but l'envoi d'un message à plusieurs client sans attendre de réponse. Cela évite de monopoliser la connexion avec le client et rend l'envoi plus rapide.

--> La connexion distante a pu être établie et fonctionne.

## Phase 2

Q2.4) Oui, le salon redémarre. Il est supervisé par un superviseur qui détecte sa terminaison (même avec :kill) et le relance automatiquement selon sa stratégie de supervision.

2.5) one_for_one: Seul le processus qui a planté est redémarré
     one_for_all: Tous les processus enfants sont redémarrés lorsque qu'un processus plante.

## Fin Phase 2 & Phase 3
--> La fonction pour récupérer les salons et la mise en mémoire des messages ont bien étés mis en place
--> La vérification des pseudos en doublon a pu être mise en place et fonctionne
--> La mise en place des commandes fonctionne également

La communication entre deux clients fonctionne, tout comme les différentes fonctionnalités mise en place. Cependant il faut faire attention à ne pas faire de fautes dans le nom du salon dans le terminal car même en le corrigeant un salon différent est créé et fausse les tests.
