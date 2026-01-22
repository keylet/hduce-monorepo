// frontend/src/services/api.ts - ARCHIVO PRINCIPAL DE API
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
  timeout: 10000,
});

// Interceptor para a�adir token autom�ticamente
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('hduce_token') || localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;

    // Verificar expiraci�n del token
    try {
      const decoded = jwtDecode<DecodedToken>(token);
      const currentTime = Date.now() / 1000;

      if (decoded.exp < currentTime) {
        // Token expirado, limpiar
        localStorage.removeItem('hduce_token');
        localStorage.removeItem('token');
        localStorage.removeItem('hduce_user');
        localStorage.removeItem('user');
        window.location.href = '/login';
        throw new Error('Token expirado');
      }
    } catch (error) {
      console.error('Error decodificando token:', error);
    }
  }
  return config;
});

// Interceptor para respuestas
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // No autorizado, limpiar y redirigir
      localStorage.removeItem('hduce_token');
      localStorage.removeItem('token');
      localStorage.removeItem('hduce_user');
      localStorage.removeItem('user');
      window.location.href = '/login';
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

// Exportar el cliente axios por si acaso
export default api;
