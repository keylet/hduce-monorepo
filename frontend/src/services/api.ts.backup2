// frontend/src/services/api.ts - ARCHIVO PRINCIPAL DE API CON REFRESH TOKEN
import axios from 'axios';
import { jwtDecode } from 'jwt-decode';
import type { DecodedToken } from '../types/hduce';
import { endpoints } from './endpoints';
import type { Doctor, Appointment, Notification, User } from '../types/hduce';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

// Flag para evitar múltiples refresh simultáneos
let isRefreshing = false;
let failedQueue: Array<{resolve: (value?: any) => void; reject: (reason?: any) => void}> = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

// Interceptor para agregar token automáticamente y manejar refresh
api.interceptors.request.use(async (config) => {
  let token = localStorage.getItem('hduce_token');
  
  if (token) {
    try {
      // Verificar si el token está próximo a expirar (< 5 minutos)
      const decoded = jwtDecode<DecodedToken>(token);
      const currentTime = Date.now() / 1000;
      const timeUntilExpiry = decoded.exp - currentTime;
      
      if (timeUntilExpiry < 300) { // 5 minutos
        console.log('[API Interceptor] Token expiring soon, attempting refresh...');
        
        if (!isRefreshing) {
          isRefreshing = true;
          
          try {
            // Intentar verificar el token (esto podría extender su validez en el backend)
            const verifyResponse = await axios.get(endpoints.auth.verify, {
              baseURL: API_URL,
              headers: { Authorization: `Bearer ${token}` }
            });
            
            if (verifyResponse.status === 200) {
              console.log('[API Interceptor] Token refreshed via verification');
              // El token sigue siendo válido, continuar
            } else {
              throw new Error('Token verification failed');
            }
          } catch (refreshError) {
            console.error('[API Interceptor] Token refresh failed:', refreshError);
            // Limpiar y redirigir a login
            localStorage.removeItem('hduce_token');
            localStorage.removeItem('hduce_user');
            window.location.href = '/login';
            return Promise.reject(refreshError);
          } finally {
            isRefreshing = false;
          }
        }
      }
      
      // Agregar token a la solicitud
      config.headers.Authorization = `Bearer ${token}`;
    } catch (error) {
      console.error('[API Interceptor] Error decoding token:', error);
    }
  }
  
  return config;
}, (error) => {
  return Promise.reject(error);
});

// Interceptor para respuestas - manejar errores 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      console.log('[API Interceptor] 401 received, redirecting to login...');
      
      // Limpiar almacenamiento local
      localStorage.removeItem('hduce_token');
      localStorage.removeItem('hduce_user');
      
      // Redirigir a login
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      
      return Promise.reject(error);
    }
    
    // Manejar otros errores
    if (error.response?.data?.detail) {
      error.message = error.response.data.detail;
    }
    
    return Promise.reject(error);
  }
);

// ========== FUNCIONES EXPORTADAS PARA DASHBOARD ==========

// Obtener usuario actual
export const getCurrentUser = async (): Promise<User> => {
  try {
    console.log('[api] Fetching current user...');
    const response = await api.get<User>(endpoints.users.me);
    console.log('[api] User data received:', response.data);
    return response.data;
  } catch (error) {
    console.error('[api] Error fetching user:', error);
    throw error;
  }
};

// Obtener lista de doctores
export const fetchDoctors = async (): Promise<Doctor[]> => {
  try {
    console.log('[api] Fetching doctors...');
    const response = await api.get<Doctor[]>(endpoints.doctors.list);
    console.log('[api] Doctors data received:', response.data?.length, 'doctors');
    return response.data || [];
  } catch (error) {
    console.error('[api] Error fetching doctors:', error);
    return [];
  }
};

// Obtener citas del usuario
export const fetchAppointments = async (): Promise<Appointment[]> => {
  try {
    console.log('[api] Fetching appointments...');
    const response = await api.get<Appointment[]>(endpoints.appointments.list);
    console.log('[api] Appointments data received:', response.data?.length, 'appointments');
    return response.data || [];
  } catch (error) {
    console.error('[api] Error fetching appointments:', error);
    return [];
  }
};

// Obtener notificaciones del usuario
export const fetchNotifications = async (): Promise<Notification[]> => {
  try {
    console.log('[api] Fetching notifications...');
    const response = await api.get<Notification[]>(endpoints.notifications.list);
    console.log('[api] Notifications data received:', response.data?.length, 'notifications');
    return response.data || [];
  } catch (error) {
    console.error('[api] Error fetching notifications:', error);
    return [];
  }
};

// Función para verificar token manualmente
export const verifyToken = async (token: string): Promise<boolean> => {
  try {
    const response = await axios.get(endpoints.auth.verify, {
      baseURL: API_URL,
      headers: { Authorization: `Bearer ${token}` },
      timeout: 5000
    });
    return response.status === 200;
  } catch {
    return false;
  }
};

// Exportar el cliente axios por si acaso
export default api;
