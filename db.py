import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

def get_connection():
    """
    Créer une connexion à la base de données PostgreSQL
    Utilise les variables d'environnement pour la configuration
    Supporte:
      - Production: DATABASE_URL (Supabase) ou variables individuelles
      - Développement: DATABASE_URL ou variables locales
    """
    # Si DATABASE_URL est disponible, l'utiliser (Supabase/production)
    database_url = os.getenv('DATABASE_URL')
    if database_url:
        return psycopg2.connect(
            database_url,
            cursor_factory=RealDictCursor
        )
    
    # Sinon, utiliser les variables individuelles (développement local)
    db_host = os.getenv('DB_HOST', 'localhost')
    db_port = os.getenv('DB_PORT', '5432')
    db_name = os.getenv('DB_NAME', 'essivivi_db')
    db_user = os.getenv('DB_USER', 'postgres')
    db_password = os.getenv('DB_PASSWORD', 'root')
    db_sslmode = os.getenv('DB_SSLMODE', 'prefer')
    
    return psycopg2.connect(
        host=db_host,
        port=int(db_port),
        database=db_name,
        user=db_user,
        password=db_password,
        sslmode=db_sslmode,
        cursor_factory=RealDictCursor
    )
