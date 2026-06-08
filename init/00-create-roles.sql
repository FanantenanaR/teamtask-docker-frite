-- Pré-requis avant la restauration du dump TeamTask.
--
-- Le dump contient au moins un objet appartenant au rôle "postgres"
-- (ex. : ALTER VIEW public.module_fonctionnalite_page_analyse_lib OWNER TO postgres;)
-- ainsi qu'un GRANT vers ce rôle.
--
-- Comme l'image utilise "bici" comme super-utilisateur, le rôle "postgres"
-- n'existe pas par défaut. On le crée ici pour que la restauration n'échoue pas
-- (l'entrypoint exécute les scripts avec ON_ERROR_STOP=1 : une seule erreur
-- interromprait toute l'initialisation).

DO
$$
BEGIN
   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'postgres') THEN
      CREATE ROLE postgres SUPERUSER LOGIN PASSWORD 'postgres';
   END IF;
END
$$;
