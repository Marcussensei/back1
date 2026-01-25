# Configuration Locale - ESSIVI Backend

## ⚠️ Important: Les fichiers `.env` ne doivent JAMAIS être commités dans Git!

Le fichier `.env` contient tes clés API privées. Il a été ajouté à `.gitignore` pour le protéger.

## Comment configurer localement?

### 1. Copier le fichier exemple

```bash
cp .env.example .env
```

### 2. Remplir les variables

Édite le `.env` avec tes vraies valeurs:

```
DATABASE_URL=postgresql://...  # Ta vraie URL Supabase
JWT_SECRET_KEY=...              # Génère une clé aléatoire
BREVO_API_KEY=xsmtpsib-...      # Ta clé API Brevo
SENDER_EMAIL=ton-email@...      # Ton email
SENDER_NAME=ESSIVI              # Nom à afficher
```

### 3. Installation & Test

```bash
pip install -r requirements.txt
python test_brevo.py    # Tester l'email
python app.py          # Lancer le serveur
```

## Variables Nécessaires

| Variable | Exemple | Où trouver |
|----------|---------|-----------|
| `DATABASE_URL` | `postgresql://user:pass@host/db` | Dashboard Supabase |
| `JWT_SECRET_KEY` | `abc123def456...` | Générer avec `secrets.token_hex(32)` |
| `BREVO_API_KEY` | `xsmtpsib-...` | Brevo → Settings → SMTP & API |
| `SENDER_EMAIL` | `noreply@example.com` | N'importe quel email |
| `SENDER_NAME` | `ESSIVI` | Nom à afficher aux clients |

## Déployer sur Render

1. Aller à https://render.com/dashboard
2. Cliquer sur le service backend
3. **Environment** → **Add Environment Variable**
4. Ajouter:
   - `BREVO_API_KEY` = ta clé API Brevo
   - `SENDER_EMAIL` = ton email d'envoi
   - `SENDER_NAME` = ton nom

5. Cliquer **Redeploy**

## Tester localement

```bash
# Tester l'email
python test_brevo.py

# Tester la base de données
python -c "from db import get_db_connection; conn = get_db_connection(); print('✅ DB OK')"

# Lancer le serveur
python app.py
```

## Troubleshooting

### "BREVO_API_KEY not found"
- Vérifier que `.env` existe dans le dossier backend
- Vérifier que `BREVO_API_KEY=...` est bien dedans
- Redémarrer le terminal Python

### ".env n'est pas dans Git (c'est normal!)"
- C'est prévu! Les secrets ne doivent jamais être dans Git
- Utilise `.env.example` pour montrer le format aux autres développeurs

### L'email n'arrive pas
- Vérifier les logs: `python test_brevo.py`
- Vérifier la Clé API (doit commencer par `xsmtpsib-`)
- Vérifier le sender email est valide

## Pour les autres développeurs

Pour que quelqu'un d'autre puisse configurer le projet:

1. Ils copient `.env.example` → `.env`
2. Ils remplissent les vraies valeurs
3. Ils testent avec `python test_brevo.py`

Le `.env.example` montre la structure sans révéler les secrets. ✅
