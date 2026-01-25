"""
Notifications module - Handle SMS and Email notifications using Brevo (Sendinblue)
"""
import os
import requests
from datetime import datetime
from pathlib import Path

# Load environment variables
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).parent.parent / '.env'
    if env_path.exists():
        load_dotenv(env_path)
except ImportError:
    pass  # dotenv not installed, will use os.getenv() only


class NotificationService:
    """Service for sending notifications using Brevo (Sendinblue)"""
    
    def __init__(self):
        self.brevo_api_key = os.getenv("BREVO_API_KEY", "")
        self.sender_email = os.getenv("SENDER_EMAIL", "noreply@essivi.com")
        self.sender_name = os.getenv("SENDER_NAME", "ESSIVI Notifications")
        
        if self.brevo_api_key:
            print("[NotificationService] Brevo initialized")
        else:
            print("[NotificationService] ⚠️  BREVO_API_KEY not set")
    
    
    def send_email(self, recipient_email: str, subject: str, body: str, html_body: str = None) -> bool:
        """
        Send email notification using Brevo API
        
        Args:
            recipient_email: Email address of recipient
            subject: Email subject
            body: Plain text body
            html_body: HTML body (optional)
        
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            if not self.brevo_api_key:
                print(f"[send_email] ❌ Brevo not configured")
                return False
            
            print(f"[send_email] Preparing email to {recipient_email}")
            
            # Brevo API endpoint
            url = "https://api.brevo.com/v3/smtp/email"
            
            # Headers with API key
            headers = {
                "api-key": self.brevo_api_key,
                "Content-Type": "application/json"
            }
            
            # Email payload
            payload = {
                "sender": {
                    "name": self.sender_name,
                    "email": self.sender_email
                },
                "to": [
                    {
                        "email": recipient_email
                    }
                ],
                "subject": subject,
                "textContent": body,
                "htmlContent": html_body or f"<p>{body}</p>"
            }
            
            print(f"[send_email] Sending via Brevo API")
            # Send email
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            
            if 200 <= response.status_code < 300:
                print(f"✅ Email sent to {recipient_email} (Status: {response.status_code})")
                return True
            else:
                print(f"❌ Brevo error: Status {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Error sending email to {recipient_email}: {str(e)}")
            import traceback
            print(traceback.format_exc())
            return False
    
    def send_sms(self, phone_number: str, message: str) -> bool:
        """
        Send SMS notification (placeholder for SMS service integration)
        
        Args:
            phone_number: Phone number (with country code)
            message: SMS message (max 160 chars)
        
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            # TODO: Integrate with SMS provider (Twilio, Africa's Talking, etc.)
            # For now, just log
            print(f"📱 SMS would be sent to {phone_number}: {message}")
            return True
        except Exception as e:
            print(f"❌ Error sending SMS: {str(e)}")
            return False
    
    def notify_agent_assignment(self, client_email: str, client_name: str, 
                                agent_name: str, agent_phone: str, 
                                delivery_address: str, delivery_id: int) -> bool:
        """
        Notify client that an agent has been assigned to their delivery
        """
        print(f"[notify_agent_assignment] Starting for delivery_id={delivery_id}, client={client_name}")
        
        subject = f"[ESSIVI] Votre livraison #{delivery_id} a été assignée"
        
        body = f"""Bonjour {client_name},

Un livreur a été assigné à votre livraison #{delivery_id}.

Détails:
- Livreur: {agent_name}
- Téléphone: {agent_phone}
- Adresse de livraison: {delivery_address}

Vous pouvez suivre votre livraison sur votre tableau de bord.

Merci de votre confiance!
ESSIVI"""
        
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #333;">Votre livraison a été assignée</h2>
                    <p>Bonjour <strong>{client_name}</strong>,</p>
                    <p>Un livreur a été assigné à votre livraison <strong>#{delivery_id}</strong>.</p>
                    
                    <div style="background-color: white; padding: 15px; border-left: 4px solid #007BFF; margin: 15px 0;">
                        <p><strong>Détails du livreur:</strong></p>
                        <ul style="list-style: none; padding-left: 0;">
                            <li>📦 <strong>Livreur:</strong> {agent_name}</li>
                            <li>📱 <strong>Téléphone:</strong> {agent_phone}</li>
                            <li>📍 <strong>Adresse:</strong> {delivery_address}</li>
                        </ul>
                    </div>
                    
                    <p>Vous pouvez suivre votre livraison en temps réel sur votre tableau de bord.</p>
                    <p style="color: #999; font-size: 12px; margin-top: 20px;">
                        © 2026 ESSIVI - Système de livraison intelligent
                    </p>
                </div>
            </body>
        </html>
        """
        
        result = self.send_email(client_email, subject, body, html_body)
        print(f"[notify_agent_assignment] Completed with result={result}")
        return result
    
    def notify_order_status_change(self, client_email: str, client_name: str,
                                   order_id: int, old_status: str, new_status: str) -> bool:
        """
        Notify client that their order status has changed
        """
        status_messages = {
            "en_attente": "en attente",
            "confirmée": "confirmée",
            "en_préparation": "en préparation",
            "prête": "prête à être livrée",
            "en_cours_de_livraison": "en cours de livraison",
            "livrée": "livrée avec succès",
            "annulée": "annulée",
            "probleme": "un problème détecté"
        }

        new_status_text = status_messages.get(new_status, new_status)

        subject = f"[ESSIVI] Commande #{order_id} - Statut mis à jour"

        body = f"""Bonjour {client_name},

Le statut de votre commande #{order_id} a été mis à jour.

Ancien statut: {old_status}
Nouveau statut: {new_status_text}

Merci de votre confiance!
ESSIVI"""

        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #333;">Votre commande a été mise à jour</h2>
                    <p>Bonjour <strong>{client_name}</strong>,</p>
                    <p>Le statut de votre commande <strong>#{order_id}</strong> a été mis à jour.</p>

                    <div style="background-color: white; padding: 15px; border-left: 4px solid #28a745; margin: 15px 0;">
                        <p><strong>Mise à jour du statut:</strong></p>
                        <ul style="list-style: none; padding-left: 0;">
                            <li>📋 <strong>Ancien statut:</strong> {old_status}</li>
                            <li>✅ <strong>Nouveau statut:</strong> <span style="color: #28a745; font-weight: bold;">{new_status_text}</span></li>
                        </ul>
                    </div>

                    <p>Vous pouvez consulter les détails de votre commande sur votre tableau de bord.</p>
                    <p style="color: #999; font-size: 12px; margin-top: 20px;">
                        © 2026 ESSIVI - Système de livraison intelligent
                    </p>
                </div>
            </body>
        </html>
        """

        return self.send_email(client_email, subject, body, html_body)

    def notify_agent_delivery_assignment(self, agent_user_id: int, agent_name: str,
                                        delivery_id: int, client_name: str,
                                        delivery_address: str) -> bool:
        """
        Notify agent that they have been assigned to a delivery (database notification)

        Args:
            agent_user_id: User ID of the agent
            agent_name: Name of the agent
            delivery_id: ID of the delivery
            client_name: Name of the client/point of sale
            delivery_address: Address of the delivery

        Returns:
            True if notification created successfully, False otherwise
        """
        try:
            print(f"[notify_agent_delivery_assignment] Creating notification for agent_user_id={agent_user_id}, delivery_id={delivery_id}")
            
            from db import get_connection

            conn = get_connection()
            cur = conn.cursor()

            # Create notification in database
            cur.execute("""
                INSERT INTO notifications (
                    utilisateur_id, titre, message, type_notification
                ) VALUES (%s, %s, %s, %s)
            """, (
                agent_user_id,
                f"Nouvelle livraison assignée",
                f"Vous avez été assigné à la livraison #{delivery_id} chez {client_name}.\nAdresse: {delivery_address}",
                "info"
            ))

            conn.commit()
            print(f"[notify_agent_delivery_assignment] Notification created successfully")
            conn.close()
            return True
        except Exception as e:
            print(f"[notify_agent_delivery_assignment] Error: {str(e)}")
            import traceback
            print(traceback.format_exc())
            return False
            print(f"✅ Notification créée pour l'agent {agent_name} (user_id: {agent_user_id})")
            return True

        except Exception as e:
            print(f"❌ Erreur lors de la création de la notification agent: {str(e)}")
            return False
        finally:
            if 'conn' in locals():
                conn.close()

# Singleton instance
_notification_service = None

def get_notification_service():
    """Get or create notification service singleton"""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
