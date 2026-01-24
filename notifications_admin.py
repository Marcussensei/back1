"""
Notifications module for Admin Dashboard
Real-time notifications for order creation, status changes, etc.
"""

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from db import get_connection
from datetime import datetime
from decimal import Decimal

notifications_bp = Blueprint('notifications', __name__, url_prefix='/notifications')

# In-memory store for demo (in production use Redis or similar)
active_admin_notifications = []

def convert_decimal(obj):
    """Convert Decimal to float"""
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

@notifications_bp.route("/admin/new-order", methods=['POST'])
@jwt_required()
def notify_new_order():
    """
    Créer une notification d'une nouvelle commande pour l'admin
    Appelé automatiquement quand un client crée une commande
    """
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        data = request.get_json()
        
        order_id = data.get("order_id")
        client_id = data.get("client_id")
        amount = data.get("amount", 0)
        
        # Récupérer infos du client
        cur.execute("""
            SELECT c.id, c.nom_point_vente, c.responsable, u.email
            FROM clients c
            JOIN users u ON c.user_id = u.id
            WHERE c.id = %s
        """, (client_id,))
        
        client = cur.fetchone()
        
        if not client:
            return {"error": "Client not found"}, 404
        
        # Créer notification
        notification = {
            "id": order_id,
            "type": "new_order",
            "title": f"Nouvelle commande #{order_id}",
            "message": f"{client['nom_point_vente']} a passé une commande",
            "client_id": client_id,
            "client_name": client['nom_point_vente'],
            "client_contact": client['responsable'] or client['email'],
            "order_id": order_id,
            "amount": amount,
            "timestamp": datetime.now().isoformat(),
            "read": False,
            "sound": True  # Déclencher le son
        }
        
        # Stocker la notification
        active_admin_notifications.append(notification)
        
        # Garder seulement les 100 dernières
        if len(active_admin_notifications) > 100:
            active_admin_notifications.pop(0)
        
        print(f"📢 Notification: Nouvelle commande #{order_id} de {client['nom_point_vente']}")
        
        return notification, 201
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500
    finally:
        conn.close()

@notifications_bp.route("/admin/status-change", methods=['POST'])
@jwt_required()
def notify_status_change():
    """
    Créer une notification de changement de statut pour l'admin
    """
    conn = get_connection()
    cur = conn.cursor()
    
    try:
        data = request.get_json()
        
        order_id = data.get("order_id")
        old_status = data.get("old_status")
        new_status = data.get("new_status")
        client_id = data.get("client_id")
        
        # Récupérer infos du client
        cur.execute("""
            SELECT c.nom_point_vente
            FROM clients c
            WHERE c.id = %s
        """, (client_id,))
        
        client = cur.fetchone()
        
        # Créer notification
        notification = {
            "id": f"{order_id}-{datetime.now().timestamp()}",
            "type": "status_change",
            "title": f"Commande #{order_id} - Statut changé",
            "message": f"{client['nom_point_vente']}: {old_status} → {new_status}",
            "order_id": order_id,
            "old_status": old_status,
            "new_status": new_status,
            "timestamp": datetime.now().isoformat(),
            "read": False,
            "sound": False  # Pas de son pour les changements de statut
        }
        
        active_admin_notifications.append(notification)
        
        if len(active_admin_notifications) > 100:
            active_admin_notifications.pop(0)
        
        return notification, 201
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500
    finally:
        conn.close()

@notifications_bp.route("/admin/agent-assignment", methods=['POST'])
@jwt_required()
def notify_agent_assignment():
    """
    Créer une notification d'assignation d'agent pour l'admin
    """
    try:
        data = request.get_json()
        
        order_id = data.get("order_id")
        agent_id = data.get("agent_id")
        agent_name = data.get("agent_name")
        
        notification = {
            "id": f"{order_id}-agent-{datetime.now().timestamp()}",
            "type": "agent_assignment",
            "title": f"Commande #{order_id} - Agent assigné",
            "message": f"Agent {agent_name} assigné à la commande",
            "order_id": order_id,
            "agent_id": agent_id,
            "agent_name": agent_name,
            "timestamp": datetime.now().isoformat(),
            "read": False,
            "sound": False
        }
        
        active_admin_notifications.append(notification)
        
        if len(active_admin_notifications) > 100:
            active_admin_notifications.pop(0)
        
        return notification, 201
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500

@notifications_bp.route("/admin/list", methods=['GET'])
@jwt_required()
def get_notifications():
    """
    Récupérer la liste des notifications pour l'admin
    """
    try:
        claims = get_jwt()
        user_role = claims.get("role")
        
        # Seul les admins peuvent voir les notifications
        if user_role != "admin":
            return {"error": "Unauthorized"}, 403
        
        # Récupérer les paramètres
        unread_only = request.args.get("unread_only", "false").lower() == "true"
        limit = request.args.get("limit", 20, type=int)
        
        # Filtrer si nécessaire
        notifications = active_admin_notifications
        
        if unread_only:
            notifications = [n for n in notifications if not n.get("read")]
        
        # Trier par timestamp décroissant (plus récentes en premier)
        notifications.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        
        # Limiter le nombre de résultats
        notifications = notifications[:limit]
        
        return {
            "notifications": notifications,
            "total": len(active_admin_notifications),
            "unread_count": len([n for n in active_admin_notifications if not n.get("read")])
        }, 200
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500


@notifications_bp.route("/admin/public-list", methods=['GET'])
def get_notifications_public():
    """
    Public debug endpoint: retourne les notifications sans authentification.
    Utile pour test rapide dans le navigateur (DEVELOPMENT ONLY).
    """
    try:
        notifications = list(active_admin_notifications)
        # Trier par timestamp décroissant si nécessaire
        notifications.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return {
            "notifications": notifications,
            "total": len(active_admin_notifications),
            "unread_count": len([n for n in active_admin_notifications if not n.get("read")])
        }, 200
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500

@notifications_bp.route("/admin/mark-read/<notification_id>", methods=['PUT'])
@jwt_required()
def mark_notification_read(notification_id):
    """
    Marquer une notification comme lue
    """
    try:
        claims = get_jwt()
        user_role = claims.get("role")
        
        if user_role != "admin":
            return {"error": "Unauthorized"}, 403
        
        # Trouver et marquer la notification
        for notif in active_admin_notifications:
            if notif.get("id") == notification_id:
                notif["read"] = True
                return {"message": "Marked as read"}, 200
        
        return {"error": "Notification not found"}, 404
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500

@notifications_bp.route("/admin/clear", methods=['DELETE'])
@jwt_required()
def clear_notifications():
    """
    Effacer toutes les notifications
    """
    try:
        claims = get_jwt()
        user_role = claims.get("role")
        
        if user_role != "admin":
            return {"error": "Unauthorized"}, 403
        
        global active_admin_notifications
        count = len(active_admin_notifications)
        active_admin_notifications = []
        
        return {"message": f"Cleared {count} notifications"}, 200
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500

@notifications_bp.route("/admin/stats", methods=['GET'])
@jwt_required()
def get_notification_stats():
    """
    Obtenir les statistiques des notifications
    """
    try:
        claims = get_jwt()
        user_role = claims.get("role")
        
        if user_role != "admin":
            return {"error": "Unauthorized"}, 403
        
        total = len(active_admin_notifications)
        unread = len([n for n in active_admin_notifications if not n.get("read")])
        
        # Compter par type
        by_type = {}
        for notif in active_admin_notifications:
            notif_type = notif.get("type", "unknown")
            by_type[notif_type] = by_type.get(notif_type, 0) + 1
        
        return {
            "total": total,
            "unread": unread,
            "by_type": by_type
        }, 200
        
    except Exception as e:
        return {"error": f"Server error: {str(e)}"}, 500

# Helper function to add notifications from other modules
def add_admin_notification(notification_type, title, message, data=None, sound=False):
    """
    Helper function called from other modules to add admin notifications
    
    Args:
        notification_type: Type of notification (new_order, status_change, agent_assignment)
        title: Notification title
        message: Notification message
        data: Additional data to attach to notification
        sound: Whether to trigger sound alert
    """
    notification = {
        "id": len(active_admin_notifications) + 1,
        "type": notification_type,
        "title": title,
        "message": message,
        "data": data or {},
        "sound": sound,
        "read": False,
        "created_at": datetime.now().isoformat(),
        "timestamp": datetime.now()
    }
    
    # Keep only last 100 notifications
    active_admin_notifications.append(notification)
    if len(active_admin_notifications) > 100:
        active_admin_notifications.pop(0)
    
    return notification