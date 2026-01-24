import React, { createContext, useState, useContext, ReactNode, useEffect, useCallback } from "react";
import { authService } from "../services/auth";
import { jwtDecode } from "jwt-decode";
import { DecodedToken } from "../types/hduce";

interface AuthContextType {
  isAuthenticated: boolean;
  isLoading: boolean;
  token: string | null;
  user: any | null;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  clearError: () => void;
  refreshToken: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<any | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Debug: log authentication state changes
  useEffect(() => {
    console.log("[AuthContext] isAuthenticated changed:", isAuthenticated);
    console.log("[AuthContext] token:", token ? "Present (length: " + token.length + ")" : "Missing");
    console.log("[AuthContext] isLoading:", isLoading);
  }, [isAuthenticated, token, isLoading]);

  // Función para verificar si un token está próximo a expirar
  const isTokenExpiringSoon = useCallback((token: string): boolean => {
    try {
      const decoded = jwtDecode<DecodedToken>(token);
      const currentTime = Date.now() / 1000;
      const timeUntilExpiry = decoded.exp - currentTime;
      
      // Si falta menos de 5 minutos para expirar, considerar que está por expirar
      return timeUntilExpiry < 300; // 5 minutos en segundos
    } catch {
      return true; // Si no se puede decodificar, considerar que expiró
    }
  }, []);

  // Función para refrescar token automáticamente
  const refreshToken = useCallback(async (): Promise<boolean> => {
    const currentToken = localStorage.getItem("hduce_token");
    if (!currentToken) return false;

    try {
      console.log("[AuthContext] Refreshing token...");
      const isValid = await authService.verifyToken(currentToken);
      if (isValid) {
        console.log("[AuthContext] Token still valid, no refresh needed");
        return true;
      }
      return false;
    } catch (error) {
      console.error("[AuthContext] Token refresh failed:", error);
      return false;
    }
  }, []);

  // Intervalo para verificar token cada minuto
  useEffect(() => {
    const checkTokenExpiry = async () => {
      const currentToken = localStorage.getItem("hduce_token");
      if (!currentToken || !token) return;

      if (isTokenExpiringSoon(currentToken)) {
        console.log("[AuthContext] Token expiring soon, attempting refresh...");
        const refreshed = await refreshToken();
        if (!refreshed) {
          console.log("[AuthContext] Token could not be refreshed, logging out");
          logout();
        }
      }
    };

    // Verificar cada 60 segundos
    const interval = setInterval(checkTokenExpiry, 60000);
    return () => clearInterval(interval);
  }, [token, isTokenExpiringSoon, refreshToken]);

  const initializeAuth = async () => {
    console.log("[AuthContext] Initializing auth...");
    const storedToken = localStorage.getItem("hduce_token"); // UNIFICADO: hduce_token
    console.log("[AuthContext] Stored token:", storedToken ? "Yes (length: " + storedToken.length + ")" : "No");

    if (storedToken) {
      try {
        // Verificar localmente primero (más rápido)
        try {
          const decoded = jwtDecode<DecodedToken>(storedToken);
          const currentTime = Date.now() / 1000;
          
          if (decoded.exp < currentTime) {
            console.log("[AuthContext] Token expired locally, clearing");
            localStorage.removeItem("hduce_token");
            localStorage.removeItem("hduce_user");
            setIsLoading(false);
            return;
          }
        } catch (decodeError) {
          console.log("[AuthContext] Error decoding token:", decodeError);
        }

        // Verificar con backend
        console.log("[AuthContext] Verifying token with backend...");
        const isValid = await authService.verifyToken(storedToken);
        if (isValid) {
          console.log("[AuthContext] Token is valid");
          setToken(storedToken);
          setIsAuthenticated(true);

          // Fetch user data
          try {
            console.log("[AuthContext] Fetching user data...");
            const userData = await authService.getCurrentUser(storedToken);
            setUser(userData);
            localStorage.setItem("hduce_user", JSON.stringify(userData));
          } catch (userError) {
            console.error("[AuthContext] Error fetching user:", userError);
          }
        } else {
          console.log("[AuthContext] Token invalid, clearing");
          localStorage.removeItem("hduce_token");
          localStorage.removeItem("hduce_user");
        }
      } catch (error) {
        console.error("[AuthContext] Token verification error:", error);
        localStorage.removeItem("hduce_token");
        localStorage.removeItem("hduce_user");
      }
    }
    setIsLoading(false);
  };

  useEffect(() => {
    initializeAuth();
  }, []);

  const login = async (email: string, password: string) => {
    console.log("[AuthContext] Login attempt:", email);
    setIsLoading(true);
    setError(null);
    try {
      console.log("[AuthContext] Calling authService.login...");
      const response = await authService.login(email, password);
      console.log("[AuthContext] Login response:", response);

      if (response.access_token) {
        console.log("[AuthContext] Token received, saving to localStorage");
        localStorage.setItem("hduce_token", response.access_token); // UNIFICADO
        setToken(response.access_token);
        setIsAuthenticated(true);
        console.log("[AuthContext] Auth state updated: isAuthenticated=true");

        // Fetch user data after login
        try {
          console.log("[AuthContext] Fetching user data after login...");
          const userData = await authService.getCurrentUser(response.access_token);
          setUser(userData);
          localStorage.setItem("hduce_user", JSON.stringify(userData)); // UNIFICADO
        } catch (userError) {
          console.error("[AuthContext] Error fetching user after login:", userError);
        }
      } else if (response.token) {
        // Fallback para compatibilidad
        console.log("[AuthContext] Token received (fallback), saving to localStorage");
        localStorage.setItem("hduce_token", response.token); // UNIFICADO
        setToken(response.token);
        setIsAuthenticated(true);
        console.log("[AuthContext] Auth state updated: isAuthenticated=true");

        // Fetch user data after login
        try {
          console.log("[AuthContext] Fetching user data after login...");
          const userData = await authService.getCurrentUser(response.token);
          setUser(userData);
          localStorage.setItem("hduce_user", JSON.stringify(userData)); // UNIFICADO
        } catch (userError) {
          console.error("[AuthContext] Error fetching user after login:", userError);
        }
      }
    } catch (error: any) {
      console.error("[AuthContext] Login error:", error);
      setError(error.message || "Login failed");
      throw error;
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    console.log("[AuthContext] Logging out...");
    localStorage.removeItem("hduce_token"); // UNIFICADO
    localStorage.removeItem("hduce_user"); // UNIFICADO
    setToken(null);
    setIsAuthenticated(false);
    setUser(null);
    setError(null);
  };

  const clearError = () => {
    setError(null);
  };

  const value = {
    isAuthenticated,
    isLoading,
    token,
    user,
    error,
    login,
    logout,
    clearError,
    refreshToken,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
