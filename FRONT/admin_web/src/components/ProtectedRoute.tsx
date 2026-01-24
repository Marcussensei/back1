import { useAuth } from '@/hooks/useAuth';
import { Navigate, useNavigate } from 'react-router-dom';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { AlertTriangle, RefreshCw, LogOut } from 'lucide-react';
interface ProtectedRouteProps {
  children: React.ReactNode;
  requireAdmin?: boolean;
}
export function ProtectedRoute({ children, requireAdmin = false }: ProtectedRouteProps) {
  const { user, loading, error, logout, refetch } = useAuth();
  const navigate = useNavigate();
  console.log('ProtectedRoute: Render - user:', !!user, 'loading:', loading, 'error:', error, 'requireAdmin:', requireAdmin);
  if (loading) {
    console.log('ProtectedRoute: Showing loading spinner');
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }
  if (error) {
    console.log('ProtectedRoute: Error detected, redirecting to auth');
    return <Navigate to="/auth" replace />;
  }
  if (!user) {
    console.log('ProtectedRoute: No user, redirecting to auth');
    return <Navigate to="/auth" replace />;
  }
  if (requireAdmin && user.role !== 'admin') {
    console.log('ProtectedRoute: User not admin, showing access denied');
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription className="text-center">
              <strong>Accès refusé</strong>
              <br />
              Vous n'avez pas les permissions nécessaires pour accéder à cette page.
              <br />
              Seuls les administrateurs peuvent accéder au tableau de bord.
            </AlertDescription>
          </Alert>
          <div className="flex justify-center mt-4">
            <Button onClick={() => { console.log('ProtectedRoute: Navigating to auth from access denied'); navigate('/auth'); }} variant="outline">
              <LogOut className="w-4 h-4 mr-2" />
              Retour à la connexion
            </Button>
          </div>
        </div>
      </div>
    );
  }
  console.log('ProtectedRoute: Rendering children');
  return <>{children}</>;
}