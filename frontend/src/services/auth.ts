import api from "./api";
import { endpoints } from "./endpoints";
import { LoginResponse, User } from "../types/hduce";

// Servicio de autenticación mejorado
export const authService = {
  // Login de usuario
  async login(email: string, password: string): Promise<LoginResponse> {
    try {
      console.log("[authService] Attempting login for:", email);
      const response = await api.post<LoginResponse>(endpoints.auth.login, {
        email,
        password,
      });
      console.log("[authService] Login response received:", response.data);

      // Asegurar que tenemos el token en la propiedad correcta
      const loginData = response.data;
      if (loginData.access_token) {
        console.log("[authService] Token found in access_token property");
        // Guardar token unificado
        localStorage.setItem("hduce_token", loginData.access_token);
        
        // Guardar información del usuario si está disponible
        if (loginData.user_id || loginData.email) {
          const userInfo = {
            id: loginData.user_id,
            email: loginData.email,
            role: loginData.role
          };
          localStorage.setItem("hduce_user", JSON.stringify(userInfo));
        }
      } else if (loginData.token) {
        console.log("[authService] Token found in token property (legacy)");
        localStorage.setItem("hduce_token", loginData.token);
      } else {
        console.error("[authService] No token found in response");
        throw new Error("No authentication token received");
      }

      return loginData;
    } catch (error) {
      console.error("[authService] Login error:", error);
      throw error;
    }
  },

  // Verificar token - versión mejorada
  async verifyToken(token: string): Promise<boolean> {
    try {
      console.log("[authService] Verifying token...");
      const response = await api.get(endpoints.auth.verify, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      console.log("[authService] Token verification successful");
      return true;
    } catch (error) {
      console.error("[authService] Token verification failed:", error);
      return false;
    }
  },

  // Obtener usuario actual
  async getCurrentUser(token: string): Promise<User> {
    try {
      console.log("[authService] Getting current user...");
      const response = await api.get<User>(endpoints.users.me, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      console.log("[authService] User data received:", response.data);
      
      // Guardar usuario en localStorage unificado
      localStorage.setItem("hduce_user", JSON.stringify(response.data));
      
      return response.data;
    } catch (error) {
      console.error("[authService] Error getting user:", error);
      throw error;
    }
  },

  // Obtener token almacenado
  getStoredToken(): string | null {
    return localStorage.getItem("hduce_token");
  },

  // Obtener usuario almacenado
  getStoredUser(): User | null {
    const userStr = localStorage.getItem("hduce_user");
    return userStr ? JSON.parse(userStr) : null;
  },

  // Logout (cliente y servidor)
  async logout(): Promise<void> {
    console.log("[authService] Logging out...");
    
    try {
      const token = localStorage.getItem("hduce_token");
      if (token) {
        // Opcional: llamar a endpoint de logout del backend si existe
        // await api.post(endpoints.auth.logout);
      }
    } catch (error) {
      console.error("[authService] Logout error:", error);
    } finally {
      // Siempre limpiar localStorage
      localStorage.removeItem("hduce_token");
      localStorage.removeItem("hduce_user");
      console.log("[authService] Local storage cleared");
    }
  },
};

// Exportación por defecto también para compatibilidad
export default authService;
