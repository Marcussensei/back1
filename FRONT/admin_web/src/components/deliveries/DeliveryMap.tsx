import { useEffect, useRef, useState } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { MapPin, Navigation, Truck } from "lucide-react";
import { Badge } from "@/components/ui/badge";

// Fix for default marker icons in Leaflet with webpack/vite
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
});

// Custom icons
const destinationIcon = new L.DivIcon({
  html: `<div class="flex items-center justify-center w-8 h-8 bg-destructive rounded-full border-2 border-white shadow-lg">
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg>
  </div>`,
  className: "",
  iconSize: [32, 32],
  iconAnchor: [16, 32],
});

const driverIcon = new L.DivIcon({
  html: `<div class="flex items-center justify-center w-10 h-10 bg-primary rounded-full border-2 border-white shadow-lg animate-pulse">
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10 17h4V5H2v12h3"/><path d="M20 17h2v-3.34a4 4 0 0 0-1.17-2.83L19 9h-5"/><path d="M14 17h1"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/></svg>
  </div>`,
  className: "",
  iconSize: [40, 40],
  iconAnchor: [20, 40],
});

interface DeliveryMapProps {
  delivery: {
    id: string;
    lat: number;
    lng: number;
    address: string;
    status: string;
    agent?: {
      name: string;
    } | null;
  };
}

// Component to update map view
const MapUpdater = ({ center }: { center: [number, number] }) => {
  const map = useMap();
  useEffect(() => {
    map.setView(center, 14);
  }, [center, map]);
  return null;
};

export const DeliveryMap = ({ delivery }: DeliveryMapProps) => {
  // Simulated driver position (slightly offset from destination)
  const [driverPosition, setDriverPosition] = useState<[number, number]>([
    delivery.lat + 0.008,
    delivery.lng - 0.005,
  ]);

  const destinationPosition: [number, number] = [delivery.lat, delivery.lng];
  const isInProgress = delivery.status === "in_progress";

  // Simulate driver movement when in progress
  useEffect(() => {
    if (!isInProgress) return;

    const interval = setInterval(() => {
      setDriverPosition((prev) => {
        const newLat = prev[0] - (prev[0] - delivery.lat) * 0.1;
        const newLng = prev[1] - (prev[1] - delivery.lng) * 0.1;
        return [newLat, newLng];
      });
    }, 3000);

    return () => clearInterval(interval);
  }, [isInProgress, delivery.lat, delivery.lng]);

  // Calculate distance
  const calculateDistance = () => {
    const R = 6371; // Earth's radius in km
    const dLat = ((destinationPosition[0] - driverPosition[0]) * Math.PI) / 180;
    const dLon = ((destinationPosition[1] - driverPosition[1]) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((driverPosition[0] * Math.PI) / 180) *
        Math.cos((destinationPosition[0] * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return (R * c).toFixed(2);
  };

  return (
    <Card className="overflow-hidden">
      <CardHeader className="pb-2">
        <CardTitle className="flex items-center justify-between text-base">
          <span className="flex items-center gap-2">
            <MapPin className="w-4 h-4 text-primary" />
            Carte en temps réel
          </span>
          {isInProgress && delivery.agent && (
            <Badge variant="outline" className="bg-primary/10 text-primary border-primary/20">
              <Navigation className="w-3 h-3 mr-1" />
              {calculateDistance()} km restants
            </Badge>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent className="p-0">
        <div className="h-[300px] relative">
          <MapContainer
            center={destinationPosition}
            zoom={14}
            scrollWheelZoom={false}
            className="h-full w-full z-0"
          >
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            <MapUpdater center={destinationPosition} />

            {/* Destination Marker */}
            <Marker position={destinationPosition} icon={destinationIcon}>
              <Popup>
                <div className="text-sm">
                  <p className="font-semibold">Destination</p>
                  <p className="text-muted-foreground">{delivery.address}</p>
                </div>
              </Popup>
            </Marker>

            {/* Driver Marker - only show if in progress and has agent */}
            {isInProgress && delivery.agent && (
              <Marker position={driverPosition} icon={driverIcon}>
                <Popup>
                  <div className="text-sm">
                    <p className="font-semibold flex items-center gap-1">
                      <Truck className="w-4 h-4" />
                      {delivery.agent.name}
                    </p>
                    <p className="text-muted-foreground">En route...</p>
                  </div>
                </Popup>
              </Marker>
            )}
          </MapContainer>

          {/* Legend */}
          <div className="absolute bottom-4 left-4 bg-background/95 backdrop-blur-sm rounded-lg p-3 shadow-lg z-[1000]">
            <div className="flex flex-col gap-2 text-xs">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 bg-destructive rounded-full" />
                <span>Destination</span>
              </div>
              {isInProgress && delivery.agent && (
                <div className="flex items-center gap-2">
                  <div className="w-4 h-4 bg-primary rounded-full animate-pulse" />
                  <span>Livreur</span>
                </div>
              )}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};
