# Base TeamTask — image PostgreSQL pré-chargée

Image Docker basée sur **PostgreSQL 16** qui restaure automatiquement le dump
SQL de la base **TeamTask** au premier démarrage.

| Paramètre        | Valeur     |
| ---------------- | ---------- |
| Utilisateur      | `bici`     |
| Mot de passe     | `bici`     |
| Base de données  | `teamtask` |
| Port             | `5432`     |

---

## 1. Contenu du dossier

```
.
├── Dockerfile                       # Construit l'image PostgreSQL + dump
├── docker-compose.yml               # Lancement simple avec volume persistant
├── .dockerignore                    # Exclut le .zip du contexte de build
├── init/
│   └── 00-create-roles.sql          # Crée le rôle "postgres" avant le restore
├── teamtask1702_202606081508.sql    # Le dump (schéma + données)
└── README.md
```

> Le dump est un export `pg_dump` au format « plain SQL » (PostgreSQL 16.11).
> Il est **intégré dans l'image** au moment du build.

---

## 2. Démarrage rapide

### Option A — Docker Compose (recommandé)

```bash
# Construit l'image et lance le conteneur en arrière-plan
docker compose up -d --build

# Suivre la restauration (peut prendre quelques minutes, dump ~88 Mo)
docker compose logs -f db
```

La base est prête quand les logs affichent :
`database system is ready to accept connections`.

Arrêter :

```bash
docker compose down            # stoppe et supprime le conteneur (garde les données)
docker compose down -v         # ... et SUPPRIME aussi les données (volume)
```

### Option B — Docker « pur »

```bash
# 1. Construire l'image
docker build -t teamtask-db .

# 2. Lancer le conteneur
docker run -d --name teamtask-db \
  -p 5432:5432 \
  -v teamtask_pgdata:/var/lib/postgresql/data \
  teamtask-db
```

---

## 3. Se connecter à la base

Depuis la machine hôte (psql installé) :

```bash
psql "postgresql://bici:bici@localhost:5432/teamtask"
```

Depuis l'intérieur du conteneur :

```bash
docker exec -it teamtask-db psql -U bici -d teamtask
```

Chaîne de connexion (applications) :

```
postgresql://bici:bici@localhost:5432/teamtask
```

Vérifier que les données sont bien là :

```bash
docker exec -it teamtask-db psql -U bici -d teamtask -c "\dt"
```

---

## 4. Réimporter le dump à zéro

⚠️ Le dump n'est restauré **qu'une seule fois**, lorsque le répertoire de
données est vide. Tant que le volume existe, relancer le conteneur ne
réimporte rien.

Pour repartir d'une base fraîche :

```bash
# Compose
docker compose down -v
docker compose up -d --build

# Docker pur
docker rm -f teamtask-db
docker volume rm teamtask_pgdata
docker run -d --name teamtask-db -p 5432:5432 \
  -v teamtask_pgdata:/var/lib/postgresql/data teamtask-db
```

Si vous remplacez le fichier `teamtask1702_202606081508.sql` par un nouveau
dump, pensez à **reconstruire l'image** (`--build`) ET à supprimer le volume.

---

## 5. Notes techniques

- **Rôle `postgres`** : le dump contient un objet appartenant au rôle
  `postgres` (et un `GRANT` associé). Comme l'image utilise `bici` comme
  super-utilisateur, ce rôle n'existe pas par défaut. Le script
  [`init/00-create-roles.sql`](init/00-create-roles.sql) le crée **avant** la
  restauration, sinon l'initialisation échouerait
  (l'entrypoint tourne avec `ON_ERROR_STOP=1`).
- **Ordre d'exécution** : les fichiers de `/docker-entrypoint-initdb.d/` sont
  joués par ordre alphabétique → `00-create-roles.sql` puis le dump
  (`01-teamtask-dump.sql`).
- **Version de l'image** : `postgres:16` (≥ 16.11) est requis car le dump
  utilise les méta-commandes psql `\restrict` / `\unrestrict`.
- **Sécurité** : le mot de passe `bici` est codé en dur pour un usage
  local/développement. Pour un environnement exposé, changez
  `POSTGRES_PASSWORD` (variable d'environnement) et n'intégrez pas le secret
  dans l'image.
```
