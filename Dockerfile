# Image PostgreSQL pré-chargée avec la base "teamtask".
#
# Le dump SQL est restauré AUTOMATIQUEMENT au tout premier démarrage du
# conteneur, via le mécanisme /docker-entrypoint-initdb.d de l'image officielle.
# Cette restauration n'a lieu QUE si le répertoire de données est vide
# (volume neuf). Voir le README pour réimporter à zéro.
#
# postgres:16 -> psql >= 16.11, requis car le dump contient les méta-commandes
# \restrict / \unrestrict introduites dans les versions récentes.
FROM postgres:16

# Identifiants par défaut (surchargables avec `-e` / `environment:` au run).
#   user / mot de passe : bici / bici
#   base                : teamtask
# L'utilisateur "bici" est créé comme super-utilisateur par l'image, ce qui
# correspond au propriétaire des objets du dump.
ENV POSTGRES_USER=bici \
    POSTGRES_PASSWORD=bici \
    POSTGRES_DB=teamtask

# Les fichiers ci-dessous sont exécutés par ordre alphabétique, en tant que
# $POSTGRES_USER, sur la base $POSTGRES_DB.

# 1) Pré-création du rôle "postgres" (un objet du dump lui appartient).
COPY init/00-create-roles.sql /docker-entrypoint-initdb.d/00-create-roles.sql

# 2) Restauration du dump complet (schéma + données).
COPY teamtask1702_202606081508.sql /docker-entrypoint-initdb.d/01-teamtask-dump.sql

EXPOSE 5432
