#!/usr/bin/env python3
"""
Migration script to add GPS columns to commandes table
"""
from db import get_connection

def apply_migration():
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # Check if columns already exist
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'commandes' AND column_name IN ('latitude', 'longitude')
        """)
        
        existing_cols = cur.fetchall()
        
        if len(existing_cols) == 2:
            print("✓ Columns already exist in commandes table")
            return True
        
        # Add columns if they don't exist
        print("Adding latitude and longitude columns to commandes table...")
        
        alter_query = """
        ALTER TABLE commandes 
        ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
        ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8);
        """
        
        cur.execute(alter_query)
        conn.commit()
        
        print("✓ Migration applied successfully!")
        print("✓ Added latitude and longitude columns to commandes table")
        
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"✗ Migration failed: {e}")
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    apply_migration()
