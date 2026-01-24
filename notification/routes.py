from flask_restx import Namespace, Resource, fields
from flask import request
from flask_jwt_extended import jwt_required, get_jwt
from datetime import datetime

from notifications_admin import active_admin_notifications


def serialize_notification(notif):
    """Convert datetime objects to ISO strings for JSON serialization"""
    notif_copy = dict(notif)
    if "timestamp" in notif_copy and isinstance(notif_copy["timestamp"], datetime):
        notif_copy["timestamp"] = notif_copy["timestamp"].isoformat()
    return notif_copy

notification_ns = Namespace(
    "notification",
    path="/notification",
    description="Admin notification endpoints (REST wrapper for dashboard)"
)

notif_model = notification_ns.model("Notification", {
    "id": fields.String(required=True),
    "type": fields.String(required=True),
    "title": fields.String(required=True),
    "message": fields.String(),
    "timestamp": fields.String(),
    "read": fields.Boolean(attribute="read"),
})


@notification_ns.route("/")
class NotificationList(Resource):
    @notification_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self):
        """Get list of admin notifications"""
        claims = get_jwt()
        role = claims.get("role")
        if role != "admin":
            return {"error": "Unauthorized"}, 403

        unread_only = request.args.get("unread_only", "false").lower() == "true"
        limit = request.args.get("limit", 50, type=int)

        notifs = list(active_admin_notifications)
        if unread_only:
            notifs = [n for n in notifs if not n.get("read")]

        # sort by timestamp (supports both str and datetime)
        try:
            notifs.sort(key=lambda x: x.get("timestamp") or "", reverse=True)
        except Exception:
            pass

        # Serialize datetime objects to ISO strings
        notifs = [serialize_notification(n) for n in notifs]

        return {
            "notifications": notifs[:limit],
            "total": len(active_admin_notifications),
            "unread_count": len([n for n in active_admin_notifications if not n.get("read")])
        }, 200


@notification_ns.route("/<string:notification_id>")
class NotificationDetail(Resource):
    @notification_ns.doc(security="BearerAuth")
    @jwt_required()
    def get(self, notification_id):
        """Get notification details and mark as read"""
        claims = get_jwt()
        role = claims.get("role")
        if role != "admin":
            return {"error": "Unauthorized"}, 403

        for notif in active_admin_notifications:
            if str(notif.get("id")) == notification_id:
                notif["read"] = True
                return serialize_notification(notif), 200

        return {"error": "Notification not found"}, 404

    @notification_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self, notification_id):
        """Delete a notification by id"""
        claims = get_jwt()
        role = claims.get("role")
        if role != "admin":
            return {"error": "Unauthorized"}, 403

        for i, notif in enumerate(active_admin_notifications):
            if str(notif.get("id")) == notification_id:
                active_admin_notifications.pop(i)
                return {"message": "Deleted"}, 200

        return {"error": "Notification not found"}, 404


@notification_ns.route("/clear")
class NotificationClear(Resource):
    @notification_ns.doc(security="BearerAuth")
    @jwt_required()
    def delete(self):
        """Clear all notifications"""
        claims = get_jwt()
        role = claims.get("role")
        if role != "admin":
            return {"error": "Unauthorized"}, 403

        count = len(active_admin_notifications)
        active_admin_notifications.clear()
        return {"message": f"Cleared {count} notifications"}, 200
