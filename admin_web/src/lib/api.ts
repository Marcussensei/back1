// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || "https://essivivi-project.onrender.com";

// API request helper
const apiRequest = async (
  endpoint: string,
  options: RequestInit = {}
) => {
  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
    credentials: 'include', // Envoyer automatiquement le cookie HTTP-only
  });

  if (!response.ok) {
    if (response.status === 401) {
      // Non autorisé, rediriger vers la connexion
      window.location.href = "/auth";
    }
    throw new Error(`API Error: ${response.statusText}`);
  }

  return response.json();
};

// Auth APIs
export const authAPI = {
  login: (email: string, password: string) =>
    apiRequest("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    }),

  logout: () => {
    // Faire un appel au backend pour supprimer le cookie
    return apiRequest("/auth/logout", {
      method: "POST",
    }).catch(() => {
      // Ignorer les erreurs, l'utilisateur est déjà déconnecté
    });
  },
};

// Agents APIs
export const agentsAPI = {
  getAll: (params?: Record<string, any>) => {
    const query = params ? new URLSearchParams(params).toString() : "";
    return apiRequest(`/agents/${query ? "?" + query : ""}`);
  },

  getById: (id: number) => apiRequest(`/agents/${id}`),

  create: (data: any) =>
    apiRequest("/agents/", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  update: (id: number, data: any) =>
    apiRequest(`/agents/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    apiRequest(`/agents/${id}`, {
      method: "DELETE",
    }),

  getLocations: () => apiRequest("/cartographie/agents/temps-reel"),

  updateLocation: (id: number, latitude: number, longitude: number) =>
    apiRequest(`/cartographie/agents/${id}/localiser`, {
      method: "PUT",
      body: JSON.stringify({ latitude, longitude }),
    }),

  getDeliveries: (agentId: number, params?: Record<string, any>) => {
    const combinedParams: Record<string, string> = { ...params, agent_id: agentId.toString() };
    const query = new URLSearchParams(combinedParams).toString();
    return apiRequest(`/livraisons/?${query}`);
  },

  getMonthlyStats: (agentId: number) => apiRequest(`/agents/${agentId}/monthly-stats`),
};

// Clients APIs
export const clientsAPI = {
  getAll: (params?: Record<string, any>) => {
    const query = params ? new URLSearchParams(params).toString() : "";
    return apiRequest(`/clients/${query ? "?" + query : ""}`);
  },

  getById: (id: number) => apiRequest(`/clients/${id}`),

  create: (data: any) =>
    apiRequest("/clients/", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  update: (id: number, data: any) =>
    apiRequest(`/clients/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    apiRequest(`/clients/${id}`, {
      method: "DELETE",
    }),

  getGeoLocations: () => apiRequest("/cartographie/clients/geo"),

  getOrders: (clientId: number, params?: Record<string, any>) => {
    const combinedParams: Record<string, string> = { ...params, client_id: clientId.toString() };
    const query = new URLSearchParams(combinedParams).toString();
    return apiRequest(`/commandes/?${query}`);
  },

  getMonthlyStats: (clientId: number) => apiRequest(`/clients/${clientId}/monthly-stats`),
};

// Commands APIs
export const commandsAPI = {
  getAll: (params?: Record<string, any>) => {
    // Filtrer les paramètres undefined et null
    const filteredParams = params
      ? Object.fromEntries(
          Object.entries(params).filter(([_, v]) => v !== undefined && v !== null)
        )
      : undefined;
    const query = filteredParams ? new URLSearchParams(filteredParams).toString() : "";
    return apiRequest(`/commandes/${query ? "?" + query : ""}`);
  },

  getById: (id: number) => apiRequest(`/commandes/${id}`),

  create: (data: any) =>
    apiRequest("/commandes/", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  update: (id: number, data: any) =>
    apiRequest(`/commandes/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  updateStatus: (id: number, statut: string) =>
    apiRequest(`/commandes/${id}`, {
      method: "PUT",
      body: JSON.stringify({ statut }),
    }),

  delete: (id: number) =>
    apiRequest(`/commandes/${id}`, {
      method: "DELETE",
    }),

  getStatistics: () => apiRequest("/commandes/statistiques/resume"),
};

// Deliveries APIs
export const deliveriesAPI = {
  getAll: (params?: Record<string, any>) => {
    const query = params ? new URLSearchParams(params).toString() : "";
    return apiRequest(`/livraisons/${query ? "?" + query : ""}`);
  },

  getById: (id: number) => apiRequest(`/livraisons/${id}`),

  create: (data: any) =>
    apiRequest("/livraisons/", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  update: (id: number, data: any) =>
    apiRequest(`/livraisons/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  updateStatus: (id: number, statut: string) =>
    apiRequest(`/livraisons/${id}/statut`, {
      method: "PUT",
      body: JSON.stringify({ statut }),
    }),

  delete: (id: number) =>
    apiRequest(`/livraisons/${id}`, {
      method: "DELETE",
    }),

  getStatistics: (params?: Record<string, any>) => {
    const query = params ? new URLSearchParams(params).toString() : "";
    return apiRequest(`/livraisons/statistiques${query ? "?" + query : ""}`);
  },

  getDayStats: (date?: string) =>
    apiRequest(`/livraisons/statistiques/jour${date ? "?date=" + date : ""}`),

  assignAgent: (id: number, agentId: number) =>
    apiRequest(`/livraisons/${id}/assign`, {
      method: "PUT",
      body: JSON.stringify({ agent_id: agentId }),
    }),
};

// Products APIs
export const productsAPI = {
  getAll: (params?: Record<string, any>) => {
    const query = params ? new URLSearchParams(params).toString() : "";
    return apiRequest(`/produits/${query ? "?" + query : ""}`);
  },

  getById: (id: number) => apiRequest(`/produits/${id}`),

  create: (data: any) =>
    apiRequest("/produits/", {
      method: "POST",
      body: JSON.stringify(data),
    }),

  update: (id: number, data: any) =>
    apiRequest(`/produits/${id}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),

  delete: (id: number) =>
    apiRequest(`/produits/${id}`, {
      method: "DELETE",
    }),

  getStocks: () => apiRequest("/produits/stocks"),

  updateStock: (produitId: number, data: any) =>
    apiRequest(`/produits/stocks/${produitId}`, {
      method: "PUT",
      body: JSON.stringify(data),
    }),
};

// Statistics APIs
export const statisticsAPI = {
  getDashboard: () => apiRequest("/statistiques/dashboard/kpi"),

  getAgentPerformance: (periode?: string) =>
    apiRequest(`/statistiques/performance/agents${periode ? "?periode=" + periode : ""}`),

  getRevenueEvolution: (periode?: string) =>
    apiRequest(`/statistiques/chiffre-affaires/evolution${periode ? "?periode=" + periode : ""}`),

  getTopClients: (limit?: number) =>
    apiRequest(`/statistiques/clients/top${limit ? "?limit=" + limit : ""}`),

  getDeliveryHeatmap: () => apiRequest("/statistiques/heatmap/livraisons"),

  getCustomReport: (dateDebut: string, dateFin: string) =>
    apiRequest(
      `/statistiques/rapport/periode?date_debut=${dateDebut}&date_fin=${dateFin}`
    ),
};

// Token management functions removed - now using HTTP-only cookies automatically