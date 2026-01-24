#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script pour déployer la base de données ESSIVIVI en ligne
Exécute le script SQL complet sur le serveur PostgreSQL
"""

import psycopg2
from psycopg2 import sql
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import logging

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Charger les variables d'environnement
load_dotenv()

class DatabaseDeployer:
    def __init__(self):
        """Initialiser le déployeur de base de données"""
        self.db_host = os.getenv('DB_HOST', 'localhost')
        self.db_port = os.getenv('DB_PORT', '5432')
        self.db_user = os.getenv('DB_USER', 'postgres')
        self.db_password = os.getenv('DB_PASSWORD', 'postgres')
        self.db_name = 'essivivi_db'
        
    def connect_to_postgres(self):
        """Connecter au serveur PostgreSQL (base par défaut)"""
        try:
            conn = psycopg2.connect(
                host=self.db_host,
                port=self.db_port,
                user=self.db_user,
                password=self.db_password,
                database='postgres'  # Connexion à la base par défaut
            )
            logger.info(f"✓ Connecté à PostgreSQL sur {self.db_host}:{self.db_port}")
            return conn
        except psycopg2.Error as e:
            logger.error(f"✗ Erreur de connexion: {e}")
            raise
    
    def database_exists(self, cursor, db_name):
        """Vérifier si la base de données existe"""
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_name,)
        )
        return cursor.fetchone() is not None
    
    def drop_database(self, cursor, db_name):
        """Supprimer la base de données existante"""
        try:
            # Terminer les connexions existantes
            cursor.execute(f"""
                SELECT pg_terminate_backend(pg_stat_activity.pid)
                FROM pg_stat_activity
                WHERE pg_stat_activity.datname = '{db_name}'
                AND pid <> pg_backend_pid();
            """)
            
            # Supprimer la base
            cursor.execute(f"DROP DATABASE IF EXISTS {db_name};")
            logger.info(f"✓ Base de données '{db_name}' supprimée")
        except psycopg2.Error as e:
            logger.error(f"✗ Erreur lors de la suppression: {e}")
            raise
    
    def load_sql_script(self, script_path):
        """Charger le script SQL"""
        try:
            with open(script_path, 'r', encoding='utf-8') as f:
                script = f.read()
            logger.info(f"✓ Script chargé: {script_path}")
            return script
        except FileNotFoundError:
            logger.error(f"✗ Script non trouvé: {script_path}")
            raise
        except Exception as e:
            logger.error(f"✗ Erreur lors de la lecture du script: {e}")
            raise
    
    def execute_sql_script(self, script):
        """Exécuter le script SQL complet"""
        conn = None
        try:
            conn = self.connect_to_postgres()
            cursor = conn.cursor()
            
            # Vérifier et supprimer la base existante si demandé
            if self.database_exists(cursor, self.db_name):
                logger.info(f"⚠ Base de données '{self.db_name}' existe déjà")
                response = input("Voulez-vous la remplacer? (y/n): ")
                if response.lower() == 'y':
                    self.drop_database(cursor, self.db_name)
                    conn.commit()
                else:
                    logger.info("Déploiement annulé par l'utilisateur")
                    return False
            
            # Scinder le script en commandes individuelles
            # PostgreSQL a besoin de cette séparation pour certaines commandes
            logger.info("Exécution du script SQL...")
            
            # Exécuter le script complet
            conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
            cursor.execute(script)
            
            logger.info("✓ Script SQL exécuté avec succès")
            
            # Vérifier les tables créées
            cursor.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_READ_COMMITTED)
            cursor.execute("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name;
            """)
            
            tables = cursor.fetchall()
            logger.info(f"\n✓ Tables créées ({len(tables)}):")
            for table in tables:
                logger.info(f"  - {table[0]}")
            
            conn.commit()
            return True
            
        except psycopg2.Error as e:
            if conn:
                conn.rollback()
            logger.error(f"✗ Erreur SQL: {e}")
            raise
        finally:
            if conn:
                cursor.close()
                conn.close()
                logger.info("✓ Connexion fermée")
    
    def verify_deployment(self):
        """Vérifier que le déploiement est complet"""
        try:
            conn = psycopg2.connect(
                host=self.db_host,
                port=self.db_port,
                user=self.db_user,
                password=self.db_password,
                database=self.db_name
            )
            cursor = conn.cursor()
            
            # Vérifier les tables principales
            tables_requises = [
                'users', 'agents', 'clients', 'produits', 'stocks',
                'commandes', 'commande_details', 'livraisons', 'paiements',
                'mouvements_stock', 'notifications'
            ]
            
            cursor.execute("""
                SELECT table_name FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name = ANY(%s);
            """, (tables_requises,))
            
            tables_trouvees = [row[0] for row in cursor.fetchall()]
            
            logger.info("\n" + "="*50)
            logger.info("VÉRIFICATION DU DÉPLOIEMENT")
            logger.info("="*50)
            
            for table in tables_requises:
                status = "✓" if table in tables_trouvees else "✗"
                logger.info(f"{status} {table}")
            
            # Vérifier les indexes
            cursor.execute("""
                SELECT indexname FROM pg_indexes 
                WHERE schemaname = 'public';
            """)
            indexes = cursor.fetchall()
            logger.info(f"\n✓ Indexes créés: {len(indexes)}")
            
            # Vérifier les vues
            cursor.execute("""
                SELECT viewname FROM pg_views 
                WHERE schemaname = 'public';
            """)
            views = cursor.fetchall()
            logger.info(f"✓ Vues créées: {len(views)}")
            for view in views:
                logger.info(f"  - {view[0]}")
            
            conn.close()
            return True
            
        except psycopg2.Error as e:
            logger.error(f"✗ Erreur lors de la vérification: {e}")
            return False
    
    def deploy(self, script_path):
        """Lancer le déploiement complet"""
        logger.info("="*50)
        logger.info("DÉPLOIEMENT ESSIVIVI - BASE DE DONNÉES")
        logger.info("="*50)
        logger.info(f"Serveur: {self.db_host}:{self.db_port}")
        logger.info(f"Utilisateur: {self.db_user}")
        logger.info(f"Base: {self.db_name}")
        logger.info("="*50)
        
        try:
            # Charger le script
            script = self.load_sql_script(script_path)
            
            # Exécuter le script
            success = self.execute_sql_script(script)
            
            if success:
                # Vérifier le déploiement
                if self.verify_deployment():
                    logger.info("\n" + "="*50)
                    logger.info("✓ DÉPLOIEMENT RÉUSSI")
                    logger.info("="*50)
                    return True
            
            return False
            
        except Exception as e:
            logger.error(f"\n✗ DÉPLOIEMENT ÉCHOUÉ: {e}")
            return False


def main():
    """Fonction principale"""
    # Déterminer le chemin du script SQL
    current_dir = Path(__file__).parent
    script_path = current_dir / 'complete_database_setup.sql'
    
    if not script_path.exists():
        logger.error(f"Script SQL non trouvé: {script_path}")
        sys.exit(1)
    
    # Créer le déployeur
    deployer = DatabaseDeployer()
    
    # Lancer le déploiement
    success = deployer.deploy(str(script_path))
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
