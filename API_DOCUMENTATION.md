# API ESSIVI - Documentation complète

## 🔐 Authentification

### POST `/auth/register`
Créer un nouveau compte utilisateur
```json
{
  "nom": "Jean Dupont",
  "email": "jean@example.com",
  "password": "motdepasse123",
  "role": "agent" // "agent", "client", "admin"
}
```

### POST `/auth/login`
Se connecter
```json
{
  "email": "jean@example.com",
  "password": "motdepasse123"
}
```
**Réponse:**
```json
{
  "access_token": "eyJhbGc..."
}
```

### GET `/me`
Récupérer le profil de l'utilisateur connecté
**Headers:** `Authorization: <token>`

---

## 📦 Livraisons

### GET `/livraisons/`
Récupérer la liste des livraisons avec filtres

**Paramètres:**
- `agent_id` (int) - Filtrer par agent
- `client_id` (int) - Filtrer par client
- `statut` (string) - Filtrer par statut
- `date_debut` (date) - Date de début
- `date_fin` (date) - Date de fin
- `montant_min` (float) - Montant minimum
- `montant_max` (float) - Montant maximum
- `page` (int, default=1) - Numéro de page
- `per_page` (int, default=20) - Résultats par page

### POST `/livraisons/`
Créer une nouvelle livraison
```json
{
  "commande_id": 1,
  "client_id": 1,
  "quantite": 10,
  "montant_percu": 5000.00,
  "latitude_gps": 48.8566,
  "longitude_gps": 2.3522,
  "adresse_livraison": "123 Rue de la Paix",
  "photo_lieu": "url_photo",
  "signature_client": "base64_signature"
}
```

### GET `/livraisons/<id>`
Récupérer les détails d'une livraison

### PUT `/livraisons/<id>`
Modifier une livraison

### DELETE `/livraisons/<id>`
Supprimer une livraison

### GET `/livraisons/statistiques/jour`
Récupérer les stats du jour
**Réponse:**
```json
{
  "nombre_livraisons": 15,
  "quantite_totale": 150,
  "montant_total": 75000.00,
  "montant_moyen": 5000.00
}
```

---

## 📋 Commandes

### GET `/commandes/`
Lister toutes les commandes

**Paramètres:**
- `client_id` (int)
- `agent_id` (int)
- `statut` (string) - "en_attente", "confirmee", "en_cours", "livree", "annulee"
- `date_debut`, `date_fin`
- `page`, `per_page`

### POST `/commandes/`
Créer une commande
```json
{
  "client_id": 1,
  "date_livraison_prevue": "2025-12-28T10:00:00",
  "notes": "Livrer rapidement",
  "items": [
    {
      "produit_id": 1,
      "quantite": 10,
      "prix_unitaire": 500.00
    }
  ]
}
```

### GET `/commandes/<id>`
Récupérer une commande avec ses articles

### PUT `/commandes/<id>`
Changer le statut d'une commande
```json
{
  "statut": "en_cours",
  "agent_id": 1
}
```

### GET `/commandes/statistiques/resume`
Résumé des commandes
```json
{
  "total_commandes": 100,
  "livrees": 85,
  "en_attente": 10,
  "en_cours": 5,
  "annulees": 0,
  "montant_total": 500000.00,
  "montant_moyen": 5000.00
}
```

---

## 📊 Statistiques

### GET `/statistiques/dashboard/kpi`
KPI du dashboard
```json
{
  "jour": {
    "livraisons": 15,
    "quantite": 150,
    "montant": 75000.00,
    "agents_actifs": 5
  },
  "semaine": {...},
  "mois": {...},
  "agents_en_tournee": 3,
  "commandes_en_attente": 5
}
```

### GET `/statistiques/performance/agents`
Performance de chaque agent

**Paramètres:**
- `periode` (string) - "jour", "semaine", "mois"

**Réponse:**
```json
{
  "agents": [
    {
      "id": 1,
      "nom": "Jean Dupont",
      "nombre_livraisons": 20,
      "quantite_totale": 200,
      "montant_total": 100000.00,
      "montant_moyen": 5000.00,
      "clients_servis": 15
    }
  ]
}
```

### GET `/statistiques/chiffre-affaires/evolution`
Evolution du CA par jour

**Paramètres:**
- `jours` (int, default=30) - Nombre de jours à afficher

### GET `/statistiques/clients/top`
Top clients

**Paramètres:**
- `limite` (int, default=10)
- `periode` (string) - "jour", "semaine", "mois"

### GET `/statistiques/zones/heatmap`
Données heatmap pour cartographie

### GET `/statistiques/rapport/periode`
Rapport détaillé

**Paramètres:**
- `date_debut` (required)
- `date_fin` (required)

---

## 🗺️ Cartographie

### GET `/cartographie/agents/temps-reel`
Positions en temps réel de tous les agents

### GET `/cartographie/agents/<agent_id>/localiser`
Position actuelle d'un agent

### PUT `/cartographie/agents/<agent_id>/localiser`
Mettre à jour la position d'un agent
```json
{
  "latitude": 48.8566,
  "longitude": 2.3522
}
```

### GET `/cartographie/clients/geo`
Positions de tous les clients

### GET `/cartographie/livraisons/trajet/<livraison_id>`
Trajet d'une livraison

### GET `/cartographie/zones/couverture`
Zones couvertes par agents

### GET `/cartographie/proximite`
Calculer distance agent-client

**Paramètres:**
- `agent_id` (required)
- `client_id` (required)

**Réponse:**
```json
{
  "distance_km": 1.2,
  "peut_livrer": true,
  "seuil_km": 2.0
}
```

---

## 🛒 Produits & Stocks

### GET `/produits/`
Lister les produits

**Paramètres:**
- `actif_only` (bool, default=true)

### POST `/produits/`
Créer un produit
```json
{
  "nom": "Eau 1.5L",
  "description": "Bouteille d'eau minérale 1.5L",
  "prix_unitaire": 500.00,
  "unite": "bouteille",
  "quantite_par_unite": 1
}
```

### GET `/produits/<id>`
Détails d'un produit avec stock

### PUT `/produits/<id>`
Modifier un produit

### GET `/produits/stocks/`
Lister les stocks

**Paramètres:**
- `critique_only` (bool, default=false)

### GET `/produits/stocks/<produit_id>`
Stock d'un produit

### POST `/produits/stocks/mouvement`
Enregistrer un mouvement de stock
```json
{
  "produit_id": 1,
  "type_mouvement": "entree",  // "entree", "sortie", "ajustement"
  "quantite": 50,
  "motif": "Nouvelle livraison fournisseur"
}
```

### GET `/produits/stocks/mouvements`
Historique des mouvements

**Paramètres:**
- `produit_id` (int)
- `jours` (int, default=30)

---

## 👥 Agents

### GET `/agents/`
Lister tous les agents

### POST `/agents/`
Créer un agent

### GET `/agents/<id>`
Détails d'un agent

### PUT `/agents/<id>`
Modifier un agent

### DELETE `/agents/<id>`
Supprimer un agent

---

## 👤 Clients

### GET `/clients/`
Lister tous les clients

### POST `/clients/`
Créer un client

### GET `/clients/<id>`
Détails d'un client

### PUT `/clients/<id>`
Modifier un client

### DELETE `/clients/<id>`
Supprimer un client

---

## 📱 Codes de statut HTTP

- `200` - Succès
- `201` - Créé
- `400` - Requête invalide
- `401` - Non authentifié
- `403` - Accès refusé
- `404` - Non trouvé
- `500` - Erreur serveur

---

## 🔐 Headers requis

```
Authorization: <token_jwt>
Content-Type: application/json
```

---

## 📝 Exemple complet: Créer une livraison

1. **Login:**
```bash
curl -X POST http://localhost:5000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"agent@essivi.com","password":"pass"}'
```

2. **Enregistrer la livraison:**
```bash
curl -X POST http://localhost:5000/livraisons/ \
  -H "Authorization: <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "commande_id": 1,
    "client_id": 1,
    "quantite": 10,
    "montant_percu": 5000,
    "latitude_gps": 48.8566,
    "longitude_gps": 2.3522,
    "adresse_livraison": "123 Rue"
  }'
```

3. **Consulter les stats:**
```bash
curl -X GET http://localhost:5000/statistiques/dashboard/kpi \
  -H "Authorization: <token>"
```

---

**Version API:** 1.0  
**Dernière mise à jour:** 2025-12-27
