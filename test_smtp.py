#!/usr/bin/env python3
"""
Test SMTP connection and email sending
Run this to diagnose SMTP configuration issues
"""

import os
import smtplib
import socket
from dotenv import load_dotenv
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

# Load environment variables
load_dotenv()

def test_smtp():
    """Test SMTP connection"""
    
    smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    sender_email = os.getenv("SENDER_EMAIL", "noreply@essivi.com")
    sender_password = os.getenv("SENDER_PASSWORD", "")
    
    print("=" * 60)
    print("SMTP Configuration Test")
    print("=" * 60)
    print(f"SMTP Server: {smtp_server}")
    print(f"SMTP Port: {smtp_port}")
    print(f"Sender Email: {sender_email}")
    print(f"Sender Password: {'*' * len(sender_password) if sender_password else '(not set)'}")
    print("=" * 60)
    
    if not sender_password:
        print("❌ ERROR: SENDER_PASSWORD is not set!")
        print("   Please set the SENDER_PASSWORD environment variable")
        return False
    
    # Test 1: DNS Resolution
    print("\n[Test 1] Testing DNS resolution...")
    try:
        ip = socket.gethostbyname(smtp_server)
        print(f"✅ DNS resolution successful: {smtp_server} -> {ip}")
    except socket.gaierror as e:
        print(f"❌ DNS resolution failed: {e}")
        return False
    
    # Test 2: Network connectivity
    print("\n[Test 2] Testing network connectivity...")
    try:
        sock = socket.create_connection((smtp_server, smtp_port), timeout=10)
        sock.close()
        print(f"✅ Network connectivity successful to {smtp_server}:{smtp_port}")
    except (socket.timeout, socket.error, OSError) as e:
        print(f"❌ Network connectivity failed: {e}")
        print(f"   Error type: {type(e).__name__}")
        return False
    
    # Test 3: SMTP connection
    print("\n[Test 3] Testing SMTP connection...")
    try:
        with smtplib.SMTP(smtp_server, smtp_port, timeout=10) as server:
            print(f"✅ SMTP connection successful")
            
            # Test 4: STARTTLS
            print("\n[Test 4] Testing STARTTLS...")
            server.starttls()
            print(f"✅ STARTTLS successful")
            
            # Test 5: Authentication
            print("\n[Test 5] Testing authentication...")
            server.login(sender_email, sender_password)
            print(f"✅ Authentication successful")
    
    except smtplib.SMTPAuthenticationError as e:
        print(f"❌ SMTP Authentication failed: {e}")
        print("   Check your SENDER_EMAIL and SENDER_PASSWORD")
        return False
    except smtplib.SMTPException as e:
        print(f"❌ SMTP error: {e}")
        return False
    except Exception as e:
        print(f"❌ Connection error: {e}")
        print(f"   Error type: {type(e).__name__}")
        return False
    
    # Test 6: Send test email
    print("\n[Test 6] Sending test email...")
    try:
        test_recipient = os.getenv("TEST_EMAIL", sender_email)
        
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "[ESSIVI TEST] SMTP Configuration Test"
        msg["From"] = sender_email
        msg["To"] = test_recipient
        msg["Date"] = datetime.now().strftime("%a, %d %b %Y %H:%M:%S %z")
        
        body = """Test email from ESSIVI backend

This email was sent successfully from your SMTP configuration.

If you received this email, your SMTP setup is working correctly!

---
ESSIVI Notification System
"""
        
        html_body = """
        <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #333;">✅ SMTP Test Successful</h2>
                    <p>This email was sent successfully from your ESSIVI backend.</p>
                    <p>If you received this email, your SMTP configuration is working correctly!</p>
                    <hr>
                    <p style="color: #999; font-size: 12px;">
                        ESSIVI Notification System - Test Email
                    </p>
                </div>
            </body>
        </html>
        """
        
        msg.attach(MIMEText(body, "plain"))
        msg.attach(MIMEText(html_body, "html"))
        
        with smtplib.SMTP(smtp_server, smtp_port, timeout=10) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        
        print(f"✅ Test email sent successfully to {test_recipient}")
        print("   Check your inbox (or spam folder) to verify")
        return True
        
    except Exception as e:
        print(f"❌ Failed to send test email: {e}")
        print(f"   Error type: {type(e).__name__}")
        return False

if __name__ == "__main__":
    print("\n")
    success = test_smtp()
    print("\n" + "=" * 60)
    if success:
        print("✅ All SMTP tests passed!")
    else:
        print("❌ SMTP tests failed. Check the errors above.")
    print("=" * 60 + "\n")
