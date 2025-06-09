# Outil de Monitoring

Ce dépôt contient un petit système de supervision constitué d'un serveur Bash et de scripts agents pour macOS et Ubuntu. Les agents collectent des informations système puis les envoient au serveur en JSON.

## Installation du serveur

1. Lancer le script `installer_server.sh` en tant qu'administrateur :

```bash
sudo ./installer_server.sh
```

Ce script :
- installe les dépendances (`jq` et `dialog`)
- copie `server/server.sh` et `server/menu.sh` dans `/opt/monitor`
- configure un service systemd `monitor-server.service` démarrant sur le port **9999**

Le service est ensuite activé et démarré automatiquement.

## Installation de l'agent (Ubuntu)

Sur la machine à superviser, exécutez :

```bash
./installer_agent.sh
```

L'installateur télécharge `agent_ubuntu.sh` dans `/opt/agent-monitor` et crée une tâche cron l'exécutant toutes les 30 minutes.

Pour macOS, le script `agents/agent_mac.sh` peut être utilisé manuellement (pas d'installateur fourni).

## Utilisation du menu

Une interface dialog permet de consulter les données reçues. Sur la machine hébergeant le serveur :

```bash
/opt/monitor/menu.sh
```

Le menu propose :
- **Voir un host** : afficher les détails d'une machine enregistrée
- **Résumé des hosts** : lister les machines connues et leurs dernières mises à jour
- **Supprimer un host** : effacer les données d'une machine

Les informations sont stockées sous `/opt/monitor/data` au format JSON.

## Fonctionnement général

- Chaque agent envoie régulièrement un JSON contenant des informations réseau, CPU, mémoire, disque et applications installées.
- `server.sh` écoute ces messages sur le port 9999 via `nc` et enregistre chaque hôte dans un fichier `hostname.json`.
- `menu.sh` lit ces fichiers et interagit via `dialog` pour les afficher ou les gérer.