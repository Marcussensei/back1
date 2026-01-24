import urllib.request
import json

data = {
    'email': 'admin@essivi.com',
    'password': 'admin123'
}

req = urllib.request.Request('http://localhost:5000/auth/login',
                            data=json.dumps(data).encode('utf-8'),
                            headers={'Content-Type': 'application/json'},
                            method='POST')

try:
    with urllib.request.urlopen(req) as response:
        print(f'Status: {response.getcode()}')
        result = json.loads(response.read().decode())
        print(f'Response: {result}')
except Exception as e:
    print(f'Erreur: {e}')