# Guide de Déploiement de la Base de Données ESSIVIVI en Ligne

## Vue d'ensemble

Ce guide explique comment déployer la base de données ESSIVIVI sur un serveur PostgreSQL en ligne. Le package inclut:

1. **complete_database_setup.sql** - Script SQL complet contenant:
   - Schéma principal
   - 8 migrations appliquées
   - Indexes, fonctions, triggers et vues
   - Données de test

2. **deploy_database.py** - Script Python de déploiement automatisé

## Prérequis

- PostgreSQL 12+ installé et en fonctionnement
- Python 3.7+
- Packages Python: `psycopg2`, `python-dotenv`

```bash
pip install psycopg2-binary python-dotenv
```

## Configuration

### 1. Variables d'environnement (.env)

Créez un fichier `.env` dans le dossier `backend/`:

```env
DB_HOST=your-server-ip
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_secure_password
```

### 2. Permissions PostgreSQL

Assurez-vous que votre utilisateur PostgreSQL a les permissions:

```sql
-- Exécuter en tant que superuser PostgreSQL
ALTER USER votre_utilisateur CREATEDB CREATEROLE;
```

## Méthode 1: Déploiement Automatisé (Recommandé)

### Commande simple:

```bash
cd backend
python deploy_database.py
```

### Processus:

1. ✓ Connexion au serveur PostgreSQL
2. ✓ Détection base existante
3. ✓ Suppression optionnelle (si elle existe)
4. ✓ Création base et tables
5. ✓ Application des migrations
6. ✓ Création des indexes et vues
7. ✓ Vérification du déploiement

## Méthode 2: Déploiement Manuel

### Avec psql (en ligne de commande):

```bash
# Se connecter à PostgreSQL
psql -h your-server-ip -U postgres

# Exécuter le script
psql -h your-server-ip -U postgres -f complete_database_setup.sql
```

### Avec un client GUI:

1. Ouvrir pgAdmin ou DBeaver
2. Nouvelle connexion vers votre serveur
3. Ouvrir le fichier `complete_database_setup.sql`
4. Exécuter le script complet

## Méthode 3: Déploiement Par Sections

Si vous préférez un contrôle granulaire:

```sql
-- 1. Créer la base
CREATE DATABASE essivivi_db;

-- 2. Connecter à la base
\c essivivi_db;

-- 3. Exécuter par section le SQL
-- ... (voir le fichier complete_database_setup.sql)
```

## Structure de la Base de Données

### Tables principales (11):

```
users              → Comptes utilisateurs (admin, agent, client)
agents             → Livreurs avec localisation
clients            → Points de vente
produits           → Catalogue des produits
stocks             → Gestion des stocks
commandes          → Commandes avec GPS et adresse
commande_details   → Lignes de commande
livraisons         → Suivi des livraisons complet
paiements          → Historique des paiements
mouvements_stock   → Historique des stocks
notifications      → Système de notifications
```

### Migrations Appliquées:

1. ✓ **migration_add_user_id.sql** - Liaison users/clients
2. ✓ **migration_add_gps_to_commandes.sql** - GPS des commandes
3. ✓ **migration_add_products_to_commandes.sql** - Format JSON des produits
4. ✓ **migration_add_adresse_livraison.sql** - Adresse de livraison
5. ✓ **migration_agents_location.sql** - Localisation des agents
6. ✓ **migration_allow_null_agent_id.sql** - Agent optionnel
7. ✓ **migration_update_livraisons_statut.sql** - Statuts livraisons
8. ✓ **migration_20251227_livraisons.sql** - Colonnes détaillées livraisons

## Vérification du Déploiement

### Après le déploiement, vérifier:

```sql
-- 1. Tables créées
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. Indexes
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public';

-- 3. Vues
SELECT viewname FROM pg_views 
WHERE schemaname = 'public';

-- 4. Données de test
SELECT * FROM users;
SELECT * FROM produits;
SELECT * FROM stocks;
```

## Données de Test Incluses

La base est créée avec des données initiales:

### Admin User:
- Email: `admin@essivi.com`
- Password: `admin123`
- Role: admin

### Produits:
1. Eau 1.5L - 500.00 CFA
2. Eau 50CL - 300.00 CFA
3. Pack 6x1.5L - 2800.00 CFA

### Stocks initiaux:
- Eau 1.5L: 100 unités
- Eau 50CL: 200 unités
- Pack: 50 unités

## Rôles et Permissions

Une application PostgreSQL user est créée:

```
Username: essivi_app
Password: essivi_password
Permissions: SELECT, INSERT, UPDATE, DELETE
```

## Dépannage

### Erreur: "psycopg2.OperationalError: could not connect to server"

```bash
# Vérifier PostgreSQL est en fonctionnement
sudo systemctl status postgresql  # Linux
pg_isready -h your-ip            # Test connexion
```

### Erreur: "permission denied for schema public"

```sql
-- Exécuter comme superuser
GRANT USAGE ON SCHEMA public TO essivi_app;
GRANT CREATE ON SCHEMA public TO essivi_app;
```

### Erreur: "database essivivi_db already exists"

Option 1: Supprimer avant:
```bash
python deploy_database.py  # Répondre 'y' à la demande
```

Option 2: Manuellement:
```sql
DROP DATABASE IF EXISTS essivivi_db;
```

## Performance et Optimisation

La base inclut:

- ✓ 20+ indexes optimisés
- ✓ Triggers pour audit automatique
- ✓ Fonctions PL/pgSQL pour logique métier
- ✓ Vues précalculées pour rapports
- ✓ Constraints de données

## Sauvegarde et Restauration

### Sauvegarde:

```bash
pg_dump -h your-ip -U postgres essivivi_db > backup.sql
```

### Restauration:

```bash
psql -h your-ip -U postgres -d essivivi_db < backup.sql
```

## Support et Questions

Pour tout problème:
1. Vérifier les logs du script Python
2. Tester la connexion PostgreSQL directement
3. Vérifier les permissions utilisateur
4. Consulter les logs PostgreSQL

## Checklist de Déploiement

- [ ] PostgreSQL installé et actif
- [ ] `.env` configuré avec bonnes credentials
- [ ] Python 3.7+ et psycopg2 installés
- [ ] Script `complete_database_setup.sql` présent
- [ ] Script `deploy_database.py` exécutable
- [ ] Sauvegarde de base existante si présente
- [ ] Déploiement lancé avec `python deploy_database.py`
- [ ] Vérification des tables créées
- [ ] Données de test visibles
- [ ] Application peut se connecter

## Prochaines Étapes

Après le déploiement:

1. Configurer l'application pour utiliser `essivi_app`
2. Modifier les mots de passe par défaut
3. Ajouter les données réelles
4. Configurer les sauvegardes automatiques
5. Mettre en place la réplication si nécessaire

---

**Version**: 2026-01-23  
**Schéma**: v1.0  
**Migrations**: 8 appliquées
