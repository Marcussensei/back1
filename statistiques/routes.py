from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required
from db import get_connection
from datetime import datetime, timedelta
from decimal import Decimal


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

stats_ns = Namespace(
    "statistiques",
    path="/statistiques",
    description="Statistics and reporting endpoints"
)


@stats_ns.route("/dashboard/kpi")
class KPIDashboard(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer tous les KPI pour le dashboard"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            # Statistiques du jour
            cur.execute("""
                SELECT
                    COUNT(*) as livraisons_jour,
                    SUM(quantite) as quantite_jour,
                    SUM(montant_percu) as montant_jour,
                    COUNT(DISTINCT agent_id) as agents_actifs
                FROM livraisons
                WHERE DATE(date_livraison) = CURRENT_DATE
            """)
            jour = cur.fetchone()
            
            # Statistiques hebdomadaires
            cur.execute("""
                SELECT
                    COUNT(*) as livraisons_semaine,
                    SUM(quantite) as quantite_semaine,
                    SUM(montant_percu) as montant_semaine
                FROM livraisons
                WHERE DATE(date_livraison) >= CURRENT_DATE - INTERVAL '7 days'
            """)
            semaine = cur.fetchone()
            
            # Statistiques mensuelles
            cur.execute("""
                SELECT
                    COUNT(*) as livraisons_mois,
                    SUM(quantite) as quantite_mois,
                    SUM(montant_percu) as montant_mois
                FROM livraisons
                WHERE DATE_TRUNC('month', date_livraison) = DATE_TRUNC('month', CURRENT_DATE)
            """)
            mois = cur.fetchone()
            
            # Agents actifs en tournée
            cur.execute("""
                SELECT COUNT(DISTINCT agent_id) as agents_en_tournee
                FROM livraisons
                WHERE DATE(date_livraison) = CURRENT_DATE AND statut = 'en_cours'
            """)
            agents = cur.fetchone()
            
            # Commandes en attente
            cur.execute("""
                SELECT COUNT(*) as commandes_en_attente
                FROM commandes
                WHERE statut = 'en_attente'
            """)
            commandes = cur.fetchone()
            
            return {
                "jour": {
                    "livraisons": jour["livraisons_jour"] or 0,
                    "quantite": jour["quantite_jour"] or 0,
                    "montant": float(jour["montant_jour"] or 0),
                    "agents_actifs": jour["agents_actifs"] or 0
                },
                "semaine": {
                    "livraisons": semaine["livraisons_semaine"] or 0,
                    "quantite": semaine["quantite_semaine"] or 0,
                    "montant": float(semaine["montant_semaine"] or 0)
                },
                "mois": {
                    "livraisons": mois["livraisons_mois"] or 0,
                    "quantite": mois["quantite_mois"] or 0,
                    "montant": float(mois["montant_mois"] or 0)
                },
                "agents_en_tournee": agents["agents_en_tournee"] or 0,
                "commandes_en_attente": commandes["commandes_en_attente"] or 0
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@stats_ns.route("/performance/agents")
class PerformanceAgents(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer la performance de chaque agent"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            periode = request.args.get("periode", "mois")  # jour, semaine, mois
            
            if periode == "jour":
                date_filter = "DATE(l.date_livraison) = CURRENT_DATE"
            elif periode == "semaine":
                date_filter = "DATE(l.date_livraison) >= CURRENT_DATE - INTERVAL '7 days'"
            else:
                date_filter = "DATE_TRUNC('month', l.date_livraison) = DATE_TRUNC('month', CURRENT_DATE)"
            
            query = f"""
                SELECT
                    a.id,
                    a.nom,
                    a.telephone,
                    a.tricycle,
                    COUNT(l.id) as nombre_livraisons,
                    SUM(l.quantite) as quantite_totale,
                    SUM(l.montant_percu) as montant_total,
                    AVG(l.montant_percu) as montant_moyen,
                    COUNT(DISTINCT l.client_id) as clients_servis,
                    ROUND(AVG(l.montant_percu)::numeric, 2) as moyenne_par_livraison
                FROM agents a
                LEFT JOIN livraisons l ON a.id = l.agent_id AND {date_filter}
                WHERE a.actif = TRUE
                GROUP BY a.id, a.nom, a.telephone, a.tricycle
                ORDER BY nombre_livraisons DESC
            """
            
            cur.execute(query)
            agents = cur.fetchall()
            
            return {"agents": convert_decimal(agents)}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@stats_ns.route("/chiffre-affaires/evolution")
class ChiffreAffairesEvolution(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Évolution du chiffre d'affaires par jour"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            jours = request.args.get("jours", default=30, type=int)
            
            cur.execute(f"""
                SELECT
                    DATE(date_livraison) as date,
                    COUNT(*) as nombre_livraisons,
                    SUM(quantite) as quantite,
                    SUM(montant_percu) as montant_total
                FROM livraisons
                WHERE DATE(date_livraison) >= CURRENT_DATE - INTERVAL '{jours} days'
                GROUP BY DATE(date_livraison)
                ORDER BY DATE(date_livraison)
            """)
            
            data = cur.fetchall()
            
            return {
                "periode": f"{jours} jours",
                "donnees": data
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@stats_ns.route("/clients/top")
class TopClients(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les meilleurs clients"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            limite = request.args.get("limite", default=10, type=int)
            periode = request.args.get("periode", "mois")
            
            if periode == "jour":
                date_filter = "DATE(l.date_livraison) = CURRENT_DATE"
            elif periode == "semaine":
                date_filter = "DATE(l.date_livraison) >= CURRENT_DATE - INTERVAL '7 days'"
            else:
                date_filter = "DATE_TRUNC('month', l.date_livraison) = DATE_TRUNC('month', CURRENT_DATE)"
            
            query = f"""
                SELECT
                    c.id,
                    c.nom_point_vente,
                    c.responsable,
                    c.telephone,
                    c.adresse,
                    COUNT(l.id) as nombre_livraisons,
                    SUM(l.quantite) as quantite_totale,
                    SUM(l.montant_percu) as montant_total,
                    AVG(l.montant_percu) as montant_moyen
                FROM clients c
                LEFT JOIN livraisons l ON c.id = l.client_id AND {date_filter}
                GROUP BY c.id, c.nom_point_vente, c.responsable, c.telephone, c.adresse
                HAVING COUNT(l.id) > 0
                ORDER BY montant_total DESC
                LIMIT %s
            """
            
            cur.execute(query, (limite,))
            clients = cur.fetchall()
            
            return {"clients": clients, "limite": limite}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@stats_ns.route("/zones/heatmap")
class ZonesHeatmap(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Récupérer les données heatmap des zones"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            cur.execute("""
                SELECT
                    latitude_gps,
                    longitude_gps,
                    montant_percu as valeur,
                    adresse_livraison as adresse
                FROM livraisons
                WHERE DATE(date_livraison) >= CURRENT_DATE - INTERVAL '30 days'
                AND latitude_gps IS NOT NULL
                AND longitude_gps IS NOT NULL
            """)
            
            points = cur.fetchall()
            
            return {"points": points}, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()


@stats_ns.route("/rapport/periode")
class RapportPeriode(Resource):
    @stats_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Rapport détaillé sur une période"""
        conn = get_connection()
        cur = conn.cursor()
        
        try:
            date_debut = request.args.get("date_debut", required=True)
            date_fin = request.args.get("date_fin", required=True)
            
            cur.execute("""
                SELECT
                    COUNT(DISTINCT l.id) as total_livraisons,
                    COUNT(DISTINCT l.agent_id) as total_agents,
                    COUNT(DISTINCT l.client_id) as total_clients,
                    SUM(l.quantite) as quantite_totale,
                    SUM(l.montant_percu) as montant_total,
                    AVG(l.montant_percu) as montant_moyen,
                    MIN(l.montant_percu) as montant_min,
                    MAX(l.montant_percu) as montant_max
                FROM livraisons l
                WHERE DATE(l.date_livraison) BETWEEN %s AND %s
            """, (date_debut, date_fin))
            
            rapport = cur.fetchone()
            
            return {
                "periode": f"{date_debut} à {date_fin}",
                "rapport": rapport
            }, 200
            
        except Exception as e:
            return {"error": f"Erreur serveur: {str(e)}"}, 500
        finally:
            conn.close()
