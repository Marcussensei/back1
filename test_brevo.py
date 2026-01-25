#!/usr/bin/env python3
"""
Test script for Brevo (Sendinblue) integration
"""
import os
import requests
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
env_path = Path(__file__).parent / '.env'
if env_path.exists():
    load_dotenv(env_path)
else:
    print("⚠️  .env file not found in", env_path)

def test_brevo():
    print("\n" + "="*60)
    print("Testing Brevo Integration")
    print("="*60 + "\n")
    
    # Test 1: Check API key
    print("Test 1: Checking Brevo API Key...")
    brevo_api_key = os.getenv('BREVO_API_KEY')
    if brevo_api_key:
        print(f"✅ Brevo API key found (length: {len(brevo_api_key)})")
    else:
        print("❌ BREVO_API_KEY not found in environment")
        return False
    
    # Test 2: Check sender email
    print("\nTest 2: Checking Sender Email...")
    sender_email = os.getenv('SENDER_EMAIL')
    if sender_email:
        print(f"✅ Sender email found: {sender_email}")
    else:
        print("❌ SENDER_EMAIL not found in environment")
        return False
    
    # Test 3: Check requests library
    print("\nTest 3: Checking requests library...")
    try:
        print(f"✅ requests library imported (version: {requests.__version__})")
    except ImportError:
        print("❌ requests library not found")
        return False
    
    # Test 4: Send test email
    print("\nTest 4: Sending test email...")
    sender_name = os.getenv('SENDER_NAME', 'ESSIVI')
    recipient_email = os.getenv('TEST_EMAIL', sender_email)
    
    print(f"  From: {sender_name} <{sender_email}>")
    print(f"  To: {recipient_email}")
    
    try:
        url = "https://api.brevo.com/v3/smtp/email"
        headers = {
            "api-key": brevo_api_key,
            "Content-Type": "application/json"
        }
        
        payload = {
            "sender": {
                "name": sender_name,
                "email": sender_email
            },
            "to": [
                {
                    "email": recipient_email
                }
            ],
            "subject": "ESSIVI Test Email - Brevo",
            "textContent": "This is a test email from ESSIVI notifications system using Brevo.",
            "htmlContent": "<h1>ESSIVI Test Email</h1><p>Brevo integration is working perfectly!</p>"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        
        if 200 <= response.status_code < 300:
            print(f"✅ Email sent successfully!")
            print(f"  Status: {response.status_code}")
            result = response.json()
            if 'messageId' in result:
                print(f"  Message ID: {result['messageId']}")
            return True
        else:
            print(f"❌ Email failed with status {response.status_code}")
            print(f"  Response: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timeout - Brevo server not responding")
        return False
    except requests.exceptions.ConnectionError as e:
        print(f"❌ Connection error: {str(e)}")
        return False
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_brevo()
    
    print("\n" + "="*60)
    if success:
        print("✅ All tests passed! Brevo is properly configured.")
    else:
        print("❌ Some tests failed. Check your configuration.")
    print("="*60 + "\n")
    
    # Instructions
    print("Next steps:")
    print("1. Go to https://www.brevo.com/fr/ and create a FREE account")
    print("2. Get your API key from Settings → SMTP & API")
    print("3. Add them to .env file:")
    print("   BREVO_API_KEY=xsmtpsib-xxxxxxxxxxxxx")
    print("   SENDER_EMAIL=your-email@example.com")
    print("   SENDER_NAME=ESSIVI")
    print("\n4. Run this test again: python test_brevo.py")
    print()
