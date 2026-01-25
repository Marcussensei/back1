# Configuration Brevo pour ESSIVI

Brevo (ancien Sendinblue) est un service d'email transactionnel gratuit et très fiable pour l'envoi de notifications.

## Avantages de Brevo

✅ **300 emails/jour gratuit** (beaucoup plus que les autres)
✅ **Pas de carte de crédit obligatoire** pour s'inscrire
✅ **Inscription très simple** - juste email et mot de passe
✅ **API très stable** - utilisé par des millions d'entreprises
✅ **Support français**

## Étapes de Configuration

### 1. Créer un compte Brevo (gratuit)

1. Aller sur https://www.brevo.com/fr/
2. Cliquer sur **"S'inscrire gratuitement"** (en haut à droite)
3. Remplir avec:
   - Email
   - Mot de passe
   - Accepter les conditions
4. Cliquer **"Créer mon compte"**
5. Vérifier votre email (confirmation)
6. Vous accédez au dashboard

### 2. Obtenir la Clé API

1. Dans le dashboard, cliquer sur **"Paramètres"** (en bas à gauche)
2. Aller à **"SMTP & API"** 
3. Copier la **Clé d'accès API** (commence par `xsmtpsib-...`)

### 3. Configuration Locale (.env)

Créer un fichier `.env` à la racine du projet backend avec:

```
BREVO_API_KEY=xsmtpsib-xxxxxxxxxxxxxxxxxxxxxxx
SENDER_EMAIL=votre-email@example.com
SENDER_NAME=ESSIVI
```

**Notes:**
- `BREVO_API_KEY` = la clé API depuis le dashboard Brevo
- `SENDER_EMAIL` = n'importe quel email (le vôtre ou un email Brevo)
- `SENDER_NAME` = nom qui apparaît dans l'email (ex: "ESSIVI Notifications")

### 4. Installation Locale

```bash
pip install -r requirements.txt
```

(requests est déjà dans requirements.txt)

### 5. Tester Localement

```bash
python test_brevo.py
```

Vous devriez voir:
```
✅ Test 1: Brevo API key trouvé
✅ Test 2: Sender email configuré
✅ Test 3: Email envoyé avec succès
```

### 6. Déployer sur Render

1. Aller à https://render.com/dashboard
2. Cliquer sur votre service backend
3. **Environment** → **Add Environment Variable**
4. Ajouter les variables:
   - `BREVO_API_KEY` = votre clé API
   - `SENDER_EMAIL` = votre email
   - `SENDER_NAME` = votre nom

5. Cliquer **Save** et **Redeploy**

### 7. Tester en Production

1. Ouvrir l'app (http://localhost:8080 ou votre URL Render)
2. Assigner un livreur à une livraison
3. Vérifier les logs pour `[send_email]` et `✅ Email sent`
4. L'email doit arriver dans la boîte de réception du client en quelques secondes

## Limites du Plan Gratuit

- **300 emails/jour** inclus (gratuit pour toujours!)
- **Contacts illimités**
- **Conservation des logs illimitée**
- Pas de limite de domaines

## Vérifier que ça Marche

Les emails d'assignation de livreur sont envoyés automatiquement quand vous utilisez l'endpoint `/livraisons/assign`.

Vérifier les statistiques dans le dashboard Brevo:
1. **Statistiques** dans le menu à gauche
2. Vous verrez chaque email envoyé avec le statut

## Troubleshooting

### "Brevo not configured"
- Vérifier que `.env` contient `BREVO_API_KEY`
- Sur Render: vérifier que les env variables sont dans le dashboard

### "Brevo error: Status 401"
- L'API key n'est pas bon
- Le copier de nouveau depuis le dashboard Brevo

### "Brevo error: Status 400"
- L'email du recipient est invalide ou mal formaté
- La clé API n'est pas complète

### L'email n'arrive pas après 5 minutes
- Vérifier les statistiques dans le dashboard Brevo
- Vérifier le spam de la boîte email destinataire
- Vérifier que le `SENDER_EMAIL` est correct

## Contact Support

- Email: support@brevo.com
- Documentation: https://developers.brevo.com/
- Chat: directement dans le dashboard Brevo

## FAQ

**Q: Mes emails vont être marqués comme spam?**
A: Non, Brevo est très respecté et vos emails arrivent dans la boîte principale.

**Q: Je peux avoir plus de 300 emails/jour?**
A: Oui, passer à un compte payant (très bon marché) ou demander une augmentation.

**Q: Je dois vérifier mon domaine?**
A: Non pour le plan gratuit, le domaine Brevo est utilisé.
