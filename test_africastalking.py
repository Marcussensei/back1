# import os
# from dotenv import load_dotenv
# import africastalking

# # Load environment variables
# load_dotenv()

# # Africa's Talking credentials
# username = os.getenv('AFRICASTALKING_USERNAME', 'sandbox')
# api_key = os.getenv('AFRICASTALKING_API_KEY', 'atsk_468bfa39c86f72b3465ee7b143a996dc71b1041046b709e938e4ba7b959fb14869bfd883')

# def test_sms():
#     try:
#         # Initialize Africa's Talking
#         africastalking.initialize(username, api_key)

#         # Get SMS service
#         sms = africastalking.SMS

#         # Test phone number (use your own number for testing)
#         test_phone = "+22897732976"  # Replace with your phone number

#         # Send test SMS
#         response = sms.send("Test SMS from Essivi", [test_phone])

#         print("✅ SMS envoyé avec succès!")
#         print(f"Response: {response}")

#         return True
#     except Exception as e:
#         print(f"❌ Erreur lors de l'envoi du SMS: {str(e)}")
#         return False

# if __name__ == "__main__":
#     print("Test d'envoi SMS avec Africa's Talking")
#     print(f"Username: {username}")
#     print(f"API Key: {api_key[:10]}...")

#     success = test_sms()

#     if success:
#         print("\n🎉 Test réussi! L'intégration Africa's Talking fonctionne.")
#     else:
#         print("\n❌ Test échoué. Vérifiez vos credentials et numéro de téléphone.")
 

import africastalking

USERNAME = "sandbox"
API_KEY = "atsk_468bfa39c86f72b3465ee7b143a996dc71b1041046b709e938e4ba7b959fb14869bfd883"

print("Username =", USERNAME)
print("API key length =", len(API_KEY))

africastalking.initialize(USERNAME, API_KEY)

sms = africastalking.SMS

try:
    response = sms.send(
        message="Test Sandbox",
        recipients=["+22897732976"]
    )
    print("SUCCESS:", response)
except Exception as e:
    print("ERROR:", str(e))
