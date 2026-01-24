#!/usr/bin/env python3
"""
Blueprint pour les endpoints API simples au niveau root
"""
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_connection

tours_bp = Blueprint('tours_bp', __name__)

@tours_bp.route('/tours', methods=['GET'])
@jwt_required()
def get_tours():
    """Récupérer la liste des tournées (regroupées par date/agent)"""
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        # Get current user ID from JWT
        current_user_id = get_jwt_identity()

        # Get agent_id for current user
        cur.execute("SELECT a.id as agent_id FROM users u LEFT JOIN agents a ON u.id = a.user_id WHERE u.id = %s", (current_user_id,))
        user_result = cur.fetchone()

        if not user_result or not user_result['agent_id']:
            return jsonify({"error": "Agent not found for user"}), 404

        agent_id = user_result['agent_id']

        # Récupérer les livraisons regroupées par jour pour cet agent
        cur.execute("""
            SELECT
                DATE(l.date_livraison) as tour_date,
                a.id as agent_id,
                a.nom as agent_name,
                COUNT(l.id) as livraisons_count,
                SUM(CASE WHEN l.statut = 'livree' THEN 1 ELSE 0 END) as completed_count,
                SUM(CASE WHEN l.statut = 'en_cours' THEN 1 ELSE 0 END) as in_progress_count,
                SUM(CASE WHEN l.statut = 'en_attente' THEN 1 ELSE 0 END) as pending_count,
                COALESCE(SUM(l.montant_percu), 0) as total_amount,
                COALESCE(SUM(l.quantite), 0) as total_quantity
            FROM livraisons l
            LEFT JOIN agents a ON l.agent_id = a.id
            WHERE l.agent_id = %s AND l.date_livraison >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY DATE(l.date_livraison), a.id, a.nom
            ORDER BY DATE(l.date_livraison) DESC, a.nom
            LIMIT 30
        """, (agent_id,))
        
        tours = cur.fetchall()
        result = []
        
        for idx, tour in enumerate(tours):
            completed = tour['completed_count'] if tour['completed_count'] else 0
            total = tour['livraisons_count'] if tour['livraisons_count'] else 1
            completion_rate = (completed / total * 100) if total > 0 else 0
            
            # Déterminer le statut de la tournée
            if completed == total and total > 0:
                status = 'completed'
            elif tour['in_progress_count'] and tour['in_progress_count'] > 0:
                status = 'in_progress'
            else:
                status = 'pending'
            
            result.append({
                "id": idx + 1,  # Tour ID virtuel
                "tour_name": f"Tournée {tour['agent_name']} - {tour['tour_date']}",
                "agent_name": tour['agent_name'] or "Agent",
                "date": tour['tour_date'].strftime("%Y-%m-%d") if tour['tour_date'] else "",
                "status": status,
                "deliveries": tour['livraisons_count'],
                "completed": completed,
                "completion_rate": round(completion_rate, 1),
                "total_amount": float(tour['total_amount']) if tour['total_amount'] else 0,
                "total_quantity": float(tour['total_quantity']) if tour['total_quantity'] else 0
            })
        
        return jsonify({"tours": result}), 200
        
    except Exception as e:
        return jsonify({"error": f"Erreur: {str(e)}"}), 500
    finally:
        conn.close()

@tours_bp.route('/tours/deliveries', methods=['GET'])
@jwt_required()
def get_tour_deliveries():
    """Récupérer les livraisons d'une tournée spécifique"""
    conn = get_connection()
    cur = conn.cursor()

    try:
        # Get current user ID from JWT
        current_user_id = get_jwt_identity()

        # Get agent_id for current user
        cur.execute("SELECT a.id as agent_id FROM users u LEFT JOIN agents a ON u.id = a.user_id WHERE u.id = %s", (current_user_id,))
        user_result = cur.fetchone()

        if not user_result or not user_result['agent_id']:
            return jsonify({"error": "Agent not found for user"}), 404

        agent_id = user_result['agent_id']

        date = request.args.get('date')
        if not date:
            return jsonify({"error": "Date required"}), 400

        # Récupérer les livraisons pour cette date et cet agent
        cur.execute("""
            SELECT l.id, c.nom_point_vente, l.adresse_livraison, l.montant_percu, l.statut, l.quantite,
                   c.telephone as telephone_client, a.nom as agent_nom, l.latitude_gps, l.longitude_gps
            FROM livraisons l
            LEFT JOIN clients c ON l.client_id = c.id
            LEFT JOIN agents a ON l.agent_id = a.id
            WHERE l.agent_id = %s AND DATE(l.date_livraison) = %s
            ORDER BY l.date_livraison
        """, (agent_id, date))

        deliveries = cur.fetchall()
        result = []

        for d in deliveries:
            result.append({
                "id": d['id'],
                "nom_point_vente": d['nom_point_vente'] or '',
                "adresse_livraison": d['adresse_livraison'] or '',
                "montant_percu": float(d['montant_percu']) if d['montant_percu'] else 0,
                "statut": d['statut'] or 'en_attente',
                "quantite": d['quantite'] or 0,
                "telephone_client": d['telephone_client'] or '',
                "agent_nom": d['agent_nom'] or '',
                "latitude_gps": float(d['latitude_gps']) if d['latitude_gps'] else 0.0,
                "longitude_gps": float(d['longitude_gps']) if d['longitude_gps'] else 0.0
            })

        return jsonify({"deliveries": result}), 200

    except Exception as e:
        return jsonify({"error": f"Erreur: {str(e)}"}), 500
    finally:
        conn.close()
