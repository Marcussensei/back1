//useAuth

import { useState, useEffect, useRef } from 'react';

interface User {
  id: number;
  nom: string;
  email: string;
  role: string;
  created_at: string;
  client_info?: {
    nom_point_vente: string;
    responsable: string;
    telephone: string;
    adresse: string;
    latitude: number;
    longitude: number;
  };
  agent_info?: {
    nom: string;
    telephone: string;
    email: string;
    tricycle: string;
    actif: boolean;
  };
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const isFetchingRef = useRef(false);

  const fetchUser = async () => {
    console.log('useAuth: fetchUser called, isFetching:', isFetchingRef.current);

    if (isFetchingRef.current) {
      console.log('useAuth: Already fetching, skipping');
      return;
    }

    isFetchingRef.current = true;
    console.log('useAuth: Starting fetch, set isFetching to true');

    try {
      console.log('useAuth: Fetching user data from /auth/me');
      const response = await fetch('https://essivivi-project.onrender.com/auth/me', {
        method: 'GET',
        headers: {
          'accept': 'application/json',
        },
        credentials: 'include', // Envoyer automatiquement le cookie HTTP-only
      });

      console.log('useAuth: Response status:', response.status);

      if (response.ok) {
        const userData = await response.json();
        console.log('useAuth: User data received:', userData);
        setUser(userData);
        setError(null);
      } else {
        console.log('useAuth: Token invalid or expired');
        setUser(null);
        setError('Session expirée');
      }
    } catch (err) {
      console.error('useAuth: Error fetching user data:', err);
      setError('Erreur de connexion');
      setUser(null);
    } finally {
      console.log('useAuth: Setting loading to false and isFetching to false');
      setLoading(false);
      isFetchingRef.current = false;
    }
  };

  const logout = () => {
    // Appeler le backend pour supprimer le cookie côté serveur
    fetch('https://essivivi-project.onrender.com/auth/logout', {
      method: 'POST',
      credentials: 'include',
    }).catch(err => console.error('Logout error:', err)).finally(() => {
      setUser(null);
      setError(null);
      window.location.href = '/auth';
    });
  };

  useEffect(() => {
    // Vérifier si l'utilisateur est connecté au chargement
    fetchUser();
  }, []);

  return {
    user,
    loading,
    error,
    logout,
    refetch: fetchUser,
  };
}
