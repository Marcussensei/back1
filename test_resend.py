#!/usr/bin/env python3
"""
Test Resend integration
Run this to diagnose Resend configuration issues
"""

import os
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_resend():
    """Test Resend configuration"""

    resend_api_key = os.getenv("RESEND_API_KEY",)
    sender_email = os.getenv("SENDER_EMAIL", "noreply@essivi.com")

    print("=" * 60)
    print("Resend Configuration Test")
    print("=" * 60)
    print(f"Resend API Key: {'*' * 10}...{resend_api_key[-4:] if resend_api_key else '(not set)'}")
    print(f"Sender Email: {sender_email}")
    print("=" * 60)

    if not resend_api_key:
        print("❌ ERROR: RESEND_API_KEY is not set!")
        print("   Please set the RESEND_API_KEY environment variable")
        return False

    # Test 1: API Key validation
    print("\n[Test 1] Testing Resend API Key...")
    try:
        headers = {
            "Authorization": f"Bearer {resend_api_key}",
            "Content-Type": "application/json"
        }
        response = requests.get("https://api.resend.com/domains", headers=headers, timeout=10)

        if response.status_code == 200:
            print("✅ API Key is valid")
        elif response.status_code == 401:
            print("❌ API Key is invalid")
            print("   Check your RESEND_API_KEY")
            return False
        else:
            print(f"❌ Unexpected response: {response.status_code}")
            print(f"   Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Error testing API key: {e}")
        return False

    # Test 2: Send test email
    print("\n[Test 2] Sending test email...")
    try:
        test_recipient = os.getenv("TEST_EMAIL", sender_email)

        url = "https://api.resend.com/emails"
        payload = {
            "from": sender_email,
            "to": [test_recipient],
            "subject": "[ESSIVI TEST] Resend Configuration Test",
            "text": "Test email from ESSIVI backend\n\nThis email was sent successfully from your Resend configuration.\n\nIf you received this email, your Resend setup is working correctly!\n\n---\nESSIVI Notification System",
            "html": """
            <html>
                <body style="font-family: Arial, sans-serif;">
                    <div style="background-color: #f5f5f5; padding: 20px; border-radius: 5px;">
                        <h2 style="color: #333;">✅ Resend Test Successful</h2>
                        <p>This email was sent successfully from your ESSIVI backend.</p>
                        <p>If you received this email, your Resend configuration is working correctly!</p>
                        <hr>
                        <p style="color: #999; font-size: 12px;">
                            ESSIVI Notification System - Test Email
                        </p>
                    </div>
                </body>
            </html>
            """
        }

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if 200 <= response.status_code < 300:
            print(f"✅ Test email sent successfully to {test_recipient}")
            print("   Check your inbox (or spam folder) to verify")
            return True
        else:
            print(f"❌ Failed to send test email: Status {response.status_code}")
            print(f"   Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Error sending test email: {e}")
        return False

if __name__ == "__main__":
    print("\n")
    success = test_resend()
    print("\n" + "=" * 60)
    if success:
        print("✅ All Resend tests passed!")
    else:
        print("❌ Resend tests failed. Check the errors above.")
    print("=" * 60 + "\n")
