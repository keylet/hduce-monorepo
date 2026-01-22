import api from './api';
import { endpoints } from './endpoints';
import type { Doctor, Appointment, Notification, User } from '../types/hduce';

// ========== FUNCIONES PARA DASHBOARD ==========

// Obtener usuario actual (necesita auth header)
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
    return []; // Retornar array vacío en caso de error
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
    return []; // Retornar array vacío en caso de error
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
    return []; // Retornar array vacío en caso de error
  }
};

// Exportar todas las funciones
export default {
  getCurrentUser,
  fetchDoctors,
  fetchAppointments,
  fetchNotifications
};
