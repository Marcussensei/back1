import { Toaster } from "@/components/ui/toaster";
import AgentDetail from "./pages/AgentDetail";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Index from "./pages/Index";
import Agents from "./pages/Agents";
import Clients from "./pages/Clients";
import ClientDetail from "./pages/ClientDetail";
import Deliveries from "./pages/Deliveries";
import DeliveryDetail from "./pages/DeliveryDetail";
import Orders from "./pages/Orders";
import Products from "./pages/Products";
import Reports from "./pages/Reports";
import Settings from "./pages/Settings";
import Auth from "./pages/Auth";
import Profile from "./pages/Profile";
import Tricycles from "./pages/Tricycles";
import ForgotPassword from "./pages/ForgotPassword";
import Map from "./pages/Map";
import OrderDetail from "./pages/OrderDetail";
import ProductDetail from "./pages/ProductDetail";
import NotFound from "./pages/NotFound";
import { ProtectedRoute } from "./components/ProtectedRoute";
const queryClient = new QueryClient();
const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/auth" element={<Auth />} />
          <Route path="/forgot-password" element={<ForgotPassword />} />
          <Route path="/" element={<ProtectedRoute requireAdmin><Index /></ProtectedRoute>} />
          <Route path="/agents" element={<ProtectedRoute requireAdmin><Agents /></ProtectedRoute>} />
          <Route path="/agents/:id" element={<ProtectedRoute requireAdmin><AgentDetail /></ProtectedRoute>} />
          <Route path="/clients" element={<ProtectedRoute requireAdmin><Clients /></ProtectedRoute>} />
          <Route path="/clients/:id" element={<ProtectedRoute requireAdmin><ClientDetail /></ProtectedRoute>} />
          <Route path="/orders" element={<ProtectedRoute requireAdmin><Orders /></ProtectedRoute>} />          <Route path="/orders/:id" element={<ProtectedRoute requireAdmin><OrderDetail /></ProtectedRoute>} />          <Route path="/products" element={<ProtectedRoute requireAdmin><Products /></ProtectedRoute>} />          <Route path="/products/:id" element={<ProtectedRoute requireAdmin><ProductDetail /></ProtectedRoute>} />          <Route path="/deliveries" element={<ProtectedRoute requireAdmin><Deliveries /></ProtectedRoute>} />
          <Route path="/deliveries/:id" element={<ProtectedRoute requireAdmin><DeliveryDetail /></ProtectedRoute>} />
          <Route path="/tricycles" element={<ProtectedRoute requireAdmin><Tricycles /></ProtectedRoute>} />
          <Route path="/map" element={<ProtectedRoute requireAdmin><Map /></ProtectedRoute>} />
          <Route path="/reports" element={<ProtectedRoute requireAdmin><Reports /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute requireAdmin><Settings /></ProtectedRoute>} />
          <Route path="/profile" element={<ProtectedRoute requireAdmin><Profile /></ProtectedRoute>} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);
export default App;
