import { useEffect, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  agentsAPI,
  clientsAPI,
  commandsAPI,
  deliveriesAPI,
  productsAPI,
  statisticsAPI,
} from "@/lib/api";

// Agents Hooks
export const useAgents = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["agents", params],
    queryFn: () => agentsAPI.getAll(params),
  });
};

export const useAgent = (id: number) => {
  return useQuery({
    queryKey: ["agent", id],
    queryFn: () => agentsAPI.getById(id),
    enabled: !!id,
  });
};

export const useCreateAgent = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => agentsAPI.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["agents"] });
    },
  });
};

export const useUpdateAgent = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, data }: { id: number; data: any }) => agentsAPI.update(id, data),
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: ["agents"] });
      queryClient.invalidateQueries({ queryKey: ["agent", id] });
    },
  });
};

export const useDeleteAgent = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => agentsAPI.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["agents"] });
    },
  });
};

export const useAgentLocations = () => {
  return useQuery({
    queryKey: ["agentLocations"],
    queryFn: () => agentsAPI.getLocations(),
    refetchInterval: 5000, // Refresh every 5 seconds
  });
};

export const useAgentDeliveries = (agentId: number, params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["agentDeliveries", agentId, params],
    queryFn: () => agentsAPI.getDeliveries(agentId, params),
    enabled: !!agentId,
  });
};

export const useAgentMonthlyStats = (agentId: number) => {
  return useQuery({
    queryKey: ["agentMonthlyStats", agentId],
    queryFn: () => agentsAPI.getMonthlyStats(agentId),
    enabled: !!agentId,
  });
};

// Clients Hooks
export const useClients = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["clients", params],
    queryFn: () => clientsAPI.getAll(params),
  });
};

export const useClient = (id: number) => {
  return useQuery({
    queryKey: ["client", id],
    queryFn: () => clientsAPI.getById(id),
    enabled: !!id,
  });
};

export const useCreateClient = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => clientsAPI.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clients"] });
    },
  });
};

export const useUpdateClient = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => clientsAPI.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clients"] });
      queryClient.invalidateQueries({ queryKey: ["client", id] });
    },
  });
};

export const useDeleteClient = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => clientsAPI.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clients"] });
    },
  });
};

export const useClientOrders = (clientId: number, params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["clientOrders", clientId, params],
    queryFn: () => clientsAPI.getOrders(clientId, params),
    enabled: !!clientId,
  });
};

export const useClientMonthlyStats = (clientId: number) => {
  return useQuery({
    queryKey: ["clientMonthlyStats", clientId],
    queryFn: () => clientsAPI.getMonthlyStats(clientId),
    enabled: !!clientId,
  });
};

// Commands Hooks
export const useCommands = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["commands", params],
    queryFn: () => commandsAPI.getAll(params),
  });
};

export const useCommand = (id: number) => {
  return useQuery({
    queryKey: ["command", id],
    queryFn: () => commandsAPI.getById(id),
    enabled: !!id,
  });
};

export const useCreateCommand = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => commandsAPI.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["commands"] });
    },
  });
};

export const useUpdateCommand = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => commandsAPI.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["commands"] });
      queryClient.invalidateQueries({ queryKey: ["command", id] });
    },
  });
};

export const useDeleteCommand = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () => commandsAPI.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["commands"] });
    },
  });
};

export const useUpdateCommandStatus = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (statut: string) => commandsAPI.updateStatus(id, statut),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["commands"] });
      queryClient.invalidateQueries({ queryKey: ["command", id] });
    },
  });
};

export const useCommandsStatistics = () => {
  return useQuery({
    queryKey: ["commands-statistics"],
    queryFn: () => commandsAPI.getStatistics(),
  });
};

// Deliveries Hooks
export const useDeliveries = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["deliveries", params],
    queryFn: () => deliveriesAPI.getAll(params),
  });
};

export const useDelivery = (id: number) => {
  return useQuery({
    queryKey: ["delivery", id],
    queryFn: () => deliveriesAPI.getById(id),
    enabled: !!id,
  });
};

export const useCreateDelivery = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => deliveriesAPI.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deliveries"] });
    },
  });
};

export const useUpdateDelivery = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => deliveriesAPI.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deliveries"] });
      queryClient.invalidateQueries({ queryKey: ["delivery", id] });
    },
  });
};

export const useUpdateDeliveryStatus = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (statut: string) => deliveriesAPI.updateStatus(id, statut),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deliveries"] });
      queryClient.invalidateQueries({ queryKey: ["delivery", id] });
    },
  });
};

export const useAssignDelivery = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (agentId: number) => deliveriesAPI.assignAgent(id, agentId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deliveries"] });
      queryClient.invalidateQueries({ queryKey: ["delivery", id] });
    },
  });
};

export const useDeliveryStatistics = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["deliveryStats", params],
    queryFn: () => deliveriesAPI.getStatistics(params),
  });
};

export const useDeliveryNotificationHistory = (deliveryId: number) => {
  return useQuery({
    queryKey: ["deliveryNotifications", deliveryId],
    queryFn: () => deliveriesAPI.getNotificationHistory(deliveryId),
    enabled: !!deliveryId,
  });
};

export const useDeliveryTrackingHistory = (deliveryId: number) => {
  return useQuery({
    queryKey: ["deliveryTracking", deliveryId],
    queryFn: () => deliveriesAPI.getTrackingHistory(deliveryId),
    enabled: !!deliveryId,
  });
};

export const useSendDeliveryNotification = (deliveryId: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => deliveriesAPI.sendNotification(deliveryId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["deliveryNotifications", deliveryId] });
    },
  });
};

// Products Hooks
export const useProducts = (params?: Record<string, any>) => {
  return useQuery({
    queryKey: ["products", params],
    queryFn: () => productsAPI.getAll(params),
  });
};

export const useProduct = (id: number) => {
  return useQuery({
    queryKey: ["product", id],
    queryFn: () => productsAPI.getById(id),
    enabled: !!id,
  });
};

export const useCreateProduct = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => productsAPI.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
    },
  });
};

export const useUpdateProduct = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => productsAPI.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["product", id] });
    },
  });
};

export const useDeleteProduct = (id: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () => productsAPI.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
    },
  });
};

export const useUpdateStock = (produitId: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: any) => productsAPI.updateStock(produitId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["products"] });
      queryClient.invalidateQueries({ queryKey: ["product", produitId] });
    },
  });
};

// Statistics Hooks
export const useDashboardStats = () => {
  return useQuery({
    queryKey: ["dashboardStats"],
    queryFn: () => statisticsAPI.getDashboard(),
    refetchInterval: 30000, // Refresh every 30 seconds
  });
};

export const useAgentPerformance = (periode?: string) => {
  return useQuery({
    queryKey: ["agentPerformance", periode],
    queryFn: () => statisticsAPI.getAgentPerformance(periode),
  });
};

export const useRevenueEvolution = (periode?: string) => {
  return useQuery({
    queryKey: ["revenueEvolution", periode],
    queryFn: () => statisticsAPI.getRevenueEvolution(periode),
  });
};

export const useTopClients = (limit?: number) => {
  return useQuery({
    queryKey: ["topClients", limit],
    queryFn: () => statisticsAPI.getTopClients(limit),
  });
};

export const useDeliveryHeatmap = () => {
  return useQuery({
    queryKey: ["deliveryHeatmap"],
    queryFn: () => statisticsAPI.getDeliveryHeatmap(),
  });
};

export const useCustomReport = (dateDebut: string, dateFin: string) => {
  return useQuery({
    queryKey: ["customReport", dateDebut, dateFin],
    queryFn: () => statisticsAPI.getCustomReport(dateDebut, dateFin),
    enabled: !!dateDebut && !!dateFin,
  });
};
// Location Hooks
export const useUpdateAgentLocation = (agentId: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ latitude, longitude }: { latitude: number; longitude: number }) =>
      agentsAPI.updateLocation(agentId, latitude, longitude),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["agentLocations"] });
    },
  });
};

export const useUpdateClientLocation = (clientId: number) => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ latitude, longitude }: { latitude: number; longitude: number }) =>
      clientsAPI.updateLocation(clientId, latitude, longitude),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["clientLocations"] });
    },
  });
};

// Hook pour mettre à jour la position toutes les 30 secondes
export const useLocationTracking = (
  entityType: "agent" | "client",
  entityId: number,
  getPosition: () => Promise<{ latitude: number; longitude: number } | null>
) => {
  const updateAgentLocation = useUpdateAgentLocation(entityId);
  const updateClientLocation = useUpdateClientLocation(entityId);

  const updateFn = entityType === "agent" ? updateAgentLocation : updateClientLocation;

  useEffect(() => {
    let intervalId: NodeJS.Timeout | null = null;

    const startTracking = async () => {
      intervalId = setInterval(async () => {
        try {
          const position = await getPosition();
          if (position) {
            updateFn.mutate(position);
          }
        } catch (error) {
          console.error("Erreur lors de la mise à jour de la position:", error);
        }
      }, 30000); // 30 secondes
    };

    if (entityId) {
      startTracking();
    }

    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
  }, [entityId, updateFn]);

  return updateFn;
};

// Hook pour obtenir la géolocalisation du navigateur
export const useGeolocation = () => {
  const [position, setPosition] = useState<{ latitude: number; longitude: number } | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!navigator.geolocation) {
      setError("La géolocalisation n'est pas supportée par ce navigateur");
      return;
    }

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        setPosition({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
        setError(null);
      },
      (error) => {
        setError(error.message);
      },
      {
        enableHighAccuracy: true,
        maximumAge: 5000, // Garder en cache 5 secondes max
        timeout: 10000,
      }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  return { position, error };
};