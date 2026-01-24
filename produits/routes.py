from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required
from db import get_connection
from datetime import datetime
from decimal import Decimal
import json


def convert_decimal(obj):
    """Convert Decimal, datetime, date, and time objects to JSON-serializable types"""
    import datetime as dt
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, (dt.datetime, dt.date, dt.time)):
        return obj.isoformat()
    if isinstance(obj, dict):
        return {k: convert_decimal(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [convert_decimal(item) for item in obj]
    return obj

produits_ns = Namespace(
    "produits",
    path="/produits",
    description="Products and stocks management"
)

# ===== Swagger Models =====
produit_model = produits_ns.model("Produit", {
    "id": fields.Integer(readonly=True),
    "nom": fields.String(required=True),
    "description": fields.String(),
    "prix_unitaire": fields.Float(required=True),
    "unite": fields.String(),
    "quantite_par_unite": fields.Integer(),
    "actif": fields.Boolean(),
})

create_produit_model = produits_ns.model("CreateProduit", {
    "nom": fields.String(required=True),
    "description": fields.String(),
    "prix_unitaire": fields.Float(required=True),
    "unite": fields.String(),
    "quantite_par_unite": fields.Integer(),
    "stock_disponible": fields.Integer(required=False),
    "seuil_alerte": fields.Integer(required=False),
})

stock_model = produits_ns.model("Stock", {
    "id": fields.Integer(readonly=True),
    "produit_id": fields.Integer(),
    "quantite_disponible": fields.Integer(),
    "seuil_alerte": fields.Integer(),
})

mouvement_stock_model = produits_ns.model("MouvementStock", {
    "produit_id": fields.Integer(required=True),
    "type_mouvement": fields.String(required=True, enum=["entree", "sortie", "ajustement"]),
    "quantite": fields.Integer(required=True),
    "motif": fields.String(),
})


@produits_ns.route("/")
class ProduitsList(Resource):
    @produits_ns.doc(security=None)
    def get(self):
        """Récupérer la liste des produits avec stock (public)"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            actif_only = request.args.get("actif_only", default=True, type=bool)
            
            # JOIN avec la table stocks pour récupérer les quantités
            query = """
                SELECT 
                    p.id,
                    p.nom,
                    p.description,
                    p.prix_unitaire,
                    p.unite,
                    p.quantite_par_unite,
                    p.actif,
                    p.created_at,
                    p.updated_at,
                    s.quantite_disponible as stock_disponible,
                    s.seuil_alerte
                FROM produits p
                LEFT JOIN stocks s ON p.id = s.produit_id
                WHERE 1=1
            """
            params = []
            
            if actif_only:
                query += " AND p.actif = TRUE"
            
            query += " ORDER BY p.nom"
            
            cur.execute(query, params)
            produits = cur.fetchall()
            
            # Convert Decimal to float
            produits = convert_decimal(produits)
            
            return {"data": produits}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @produits_ns.doc(security="BearerAuth")
    @produits_ns.expect(create_produit_model)
    @jwt_required()
    def post(self):
        """Créer un nouveau produit avec son stock"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            now = datetime.now()
            
            # 1. Créer le produit
            cur.execute("""
                INSERT INTO produits (nom, description, prix_unitaire, unite, quantite_par_unite, actif, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, TRUE, %s, %s)
                RETURNING id, created_at, updated_at
            """, (
                data.get("nom"),
                data.get("description"),
                data.get("prix_unitaire"),
                data.get("unite", "bouteille"),
                data.get("quantite_par_unite", 1),
                now,
                now
            ))
            
            product_result = cur.fetchone()
            product_id = product_result["id"]
            
            # 2. Créer l'entrée de stock
            stock_disponible = data.get("stock_disponible", 0)
            seuil_alerte = data.get("seuil_alerte", 10)
            
            cur.execute("""
                INSERT INTO stocks (produit_id, quantite_disponible, seuil_alerte, depot_principal, created_at, updated_at)
                VALUES (%s, %s, %s, TRUE, %s, %s)
                RETURNING id
            """, (
                product_id,
                stock_disponible,
                seuil_alerte,
                now,
                now
            ))
            
            stock_result = cur.fetchone()
            conn.commit()
            
            return {
                "message": "Produit créé avec stock",
                "produit_id": product_id,
                "stock_id": stock_result["id"],
                "created_at": product_result["created_at"].isoformat(),
                "updated_at": product_result["updated_at"].isoformat(),
                "stock_disponible": stock_disponible,
                "seuil_alerte": seuil_alerte
            }, 201
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@produits_ns.route("/<int:produit_id>")
class ProduitDetail(Resource):
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, produit_id):
        """Récupérer les détails d'un produit avec son stock"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    p.id,
                    p.nom,
                    p.description,
                    p.prix_unitaire,
                    p.unite,
                    p.quantite_par_unite,
                    p.actif,
                    p.created_at,
                    s.quantite_disponible,
                    s.seuil_alerte
                FROM produits p
                LEFT JOIN stocks s ON p.id = s.produit_id
                WHERE p.id = %s
            """, (produit_id,))
            
            produit = cur.fetchone()
            
            if not produit:
                return {"error": "Produit non trouvé"}, 404
            
            return convert_decimal(produit), 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @produits_ns.doc(security="BearerAuth")
    @produits_ns.expect(create_produit_model)
    @jwt_required()
    def put(self, produit_id):
        """Modifier un produit"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            
            cur.execute("""
                UPDATE produits
                SET
                    nom = COALESCE(%s, nom),
                    description = COALESCE(%s, description),
                    prix_unitaire = COALESCE(%s, prix_unitaire),
                    unite = COALESCE(%s, unite),
                    quantite_par_unite = COALESCE(%s, quantite_par_unite),
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
                RETURNING id, updated_at
            """, (
                data.get("nom"),
                data.get("description"),
                data.get("prix_unitaire"),
                data.get("unite"),
                data.get("quantite_par_unite"),
                produit_id
            ))
            
            result = cur.fetchone()
            
            if not result:
                return {"error": "Produit non trouvé"}, 404
            
            conn.commit()
            
            return {
                "message": "Produit modifié",
                "produit_id": result["id"],
                "updated_at": result["updated_at"].isoformat()
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, produit_id):
        """Supprimer un produit"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            # Vérifier que le produit existe
            cur.execute("SELECT id FROM produits WHERE id = %s", (produit_id,))
            produit = cur.fetchone()
            
            if not produit:
                return {"error": "Produit non trouvé"}, 404
            
            # Supprimer les mouvements de stock associés
            cur.execute("DELETE FROM mouvements_stock WHERE produit_id = %s", (produit_id,))
            
            # Supprimer le stock associé
            cur.execute("DELETE FROM stocks WHERE produit_id = %s", (produit_id,))
            
            # Supprimer le produit
            cur.execute("DELETE FROM produits WHERE id = %s", (produit_id,))
            
            conn.commit()
            
            return {
                "message": "Produit supprimé",
                "produit_id": produit_id
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@produits_ns.route("/stocks/")
class StocksList(Resource):
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la liste des stocks avec alertes"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            critique_only = request.args.get("critique_only", default=False, type=bool)
            
            if critique_only:
                cur.execute("""
                    SELECT
                        s.id,
                        s.produit_id,
                        p.nom,
                        p.prix_unitaire,
                        s.quantite_disponible,
                        s.seuil_alerte,
                        CASE
                            WHEN s.quantite_disponible <= s.seuil_alerte THEN 'CRITIQUE'
                            WHEN s.quantite_disponible <= s.seuil_alerte * 1.5 THEN 'ATTENTION'
                            ELSE 'NORMAL'
                        END as statut_stock
                    FROM stocks s
                    JOIN produits p ON s.produit_id = p.id
                    WHERE s.quantite_disponible <= s.seuil_alerte
                    ORDER BY s.quantite_disponible ASC
                """)
            else:
                cur.execute("""
                    SELECT
                        s.id,
                        s.produit_id,
                        p.nom,
                        p.prix_unitaire,
                        s.quantite_disponible,
                        s.seuil_alerte,
                        CASE
                            WHEN s.quantite_disponible <= s.seuil_alerte THEN 'CRITIQUE'
                            WHEN s.quantite_disponible <= s.seuil_alerte * 1.5 THEN 'ATTENTION'
                            ELSE 'NORMAL'
                        END as statut_stock
                    FROM stocks s
                    JOIN produits p ON s.produit_id = p.id
                    ORDER BY s.quantite_disponible ASC
                """)
            
            stocks = cur.fetchall()
            
            return {"stocks": convert_decimal(stocks)}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@produits_ns.route("/stocks/<int:produit_id>")
class StockDetail(Resource):
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, produit_id):
        """Récupérer le stock d'un produit"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    s.id,
                    s.produit_id,
                    p.nom,
                    s.quantite_disponible,
                    s.seuil_alerte,
                    CASE
                        WHEN s.quantite_disponible <= s.seuil_alerte THEN 'CRITIQUE'
                        WHEN s.quantite_disponible <= s.seuil_alerte * 1.5 THEN 'ATTENTION'
                        ELSE 'NORMAL'
                    END as statut
                FROM stocks s
                JOIN produits p ON s.produit_id = p.id
                WHERE s.produit_id = %s
            """, (produit_id,))
            
            stock = cur.fetchone()
            
            if not stock:
                return {"error": "Stock non trouvé"}, 404
            
            return stock, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
    
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def put(self, produit_id):
        """Modifier la quantité de stock d'un produit"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            quantite_disponible = data.get("quantite_disponible")
            seuil_alerte = data.get("seuil_alerte")
            motif = data.get("motif", "Ajustement manuel")
            
            if quantite_disponible is None:
                return {"error": "quantite_disponible est requis"}, 400
            
            # Vérifier que le stock existe et récupérer l'ancienne quantité
            cur.execute("SELECT id, quantite_disponible FROM stocks WHERE produit_id = %s", (produit_id,))
            stock = cur.fetchone()
            
            if not stock:
                return {"error": "Stock non trouvé"}, 404
            
            ancienne_quantite = stock["quantite_disponible"]
            
            # Mettre à jour le stock
            query = "UPDATE stocks SET quantite_disponible = %s"
            params = [quantite_disponible, produit_id]
            
            if seuil_alerte is not None:
                query += ", seuil_alerte = %s"
                params.insert(1, seuil_alerte)
            
            query += " WHERE produit_id = %s RETURNING id, quantite_disponible, seuil_alerte"
            
            cur.execute(query, params)
            result = cur.fetchone()
            
            # Enregistrer le mouvement de stock
            diff = quantite_disponible - ancienne_quantite
            type_mouvement = "entree" if diff > 0 else "sortie" if diff < 0 else "ajustement"
            
            if diff != 0:
                cur.execute("""
                    INSERT INTO mouvements_stock (
                        produit_id, type_mouvement, quantite, motif, date_mouvement
                    )
                    VALUES (%s, %s, %s, %s, %s)
                """, (
                    produit_id,
                    type_mouvement,
                    abs(diff),
                    motif,
                    datetime.now()
                ))
            
            conn.commit()
            
            return {
                "message": "Stock mis à jour",
                "stock": convert_decimal(result),
                "mouvement": {
                    "type": type_mouvement,
                    "quantite": abs(diff),
                    "motif": motif
                }
            }, 200
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@produits_ns.route("/stocks/mouvement")
class MouvementStockCreate(Resource):
    @produits_ns.doc(security="BearerAuth")
    @produits_ns.expect(mouvement_stock_model)
    @jwt_required()
    def post(self):
        """Enregistrer un mouvement de stock"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            data = request.get_json()
            type_mouvement = data.get("type_mouvement")
            quantite = data.get("quantite")
            produit_id = data.get("produit_id")
            
            # Valider le type
            if type_mouvement not in ["entree", "sortie", "ajustement"]:
                return {"error": "Type de mouvement invalide"}, 400
            
            # Enregistrer le mouvement
            cur.execute("""
                INSERT INTO mouvements_stock (
                    produit_id, type_mouvement, quantite, motif, utilisateur_id, date_mouvement
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                produit_id,
                type_mouvement,
                quantite,
                data.get("motif"),
                None,  # À mettre à jour avec user_id si nécessaire
                datetime.now()
            ))
            
            mouvement_id = cur.fetchone()["id"]
            
            # Mettre à jour le stock
            if type_mouvement == "entree":
                cur.execute(
                    "UPDATE stocks SET quantite_disponible = quantite_disponible + %s WHERE produit_id = %s",
                    (quantite, produit_id)
                )
            elif type_mouvement == "sortie":
                cur.execute(
                    "UPDATE stocks SET quantite_disponible = quantite_disponible - %s WHERE produit_id = %s",
                    (quantite, produit_id)
                )
            elif type_mouvement == "ajustement":
                cur.execute(
                    "UPDATE stocks SET quantite_disponible = %s WHERE produit_id = %s",
                    (quantite, produit_id)
                )
            
            conn.commit()
            
            return {
                "message": "Mouvement enregistré",
                "mouvement_id": mouvement_id
            }, 201
            
        except Exception as e:
            conn.rollback()
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@produits_ns.route("/stocks/mouvements")
class MouvementsHistorique(Resource):
    @produits_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer l'historique des mouvements de stock"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            produit_id = request.args.get("produit_id", type=int)
            jours = request.args.get("jours", default=30, type=int)
            
            query = f"""
                SELECT
                    m.id,
                    m.produit_id,
                    p.nom,
                    m.type_mouvement,
                    m.quantite,
                    m.motif,
                    m.date_mouvement
                FROM mouvements_stock m
                JOIN produits p ON m.produit_id = p.id
                WHERE m.date_mouvement >= CURRENT_DATE - INTERVAL '{jours} days'
            """
            
            params = []
            
            if produit_id:
                query += " AND m.produit_id = %s"
                params.append(produit_id)
            
            query += " ORDER BY m.date_mouvement DESC"
            
            cur.execute(query, params)
            mouvements = cur.fetchall()
            
            return {"mouvements": convert_decimal(mouvements)}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
