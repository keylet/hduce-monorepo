// frontend/src/types/hduce.ts - VERSIÓN CORREGIDA

// ========== USER & AUTH ==========
export interface User {
  id: number;
  email: string;
  username: string;
  name?: string;
  age?: number;
  role: 'patient' | 'doctor' | 'admin';
  created_at?: string;
}

export interface AuthContextType {
  isAuthenticated: boolean;
  loading: boolean;  // AGREGADO: Para ProtectedRoute.tsx
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  user_id: number;
  email: string;
  role: string;
  // Campos de compatibilidad
  token?: string;
  user?: User;
}

export interface DecodedToken {
  sub: string;
  email: string;
  username: string;
  user_id: number;
  exp: number;
  iat: number;
}

// ========== SPECIALTY & DOCTOR ==========
export interface Specialty {
  id: number;
  name: string;
  description?: string;
  created_at?: string | null;
}

export interface Doctor {
  id: number;
  name: string;
  email: string;
  phone: string;
  specialty_id: number;
  is_active: boolean;
  created_at?: string | null;
  specialty: Specialty | string;
  available?: boolean;
  available_days?: string[];
  available_hours?: string;
}

// ========== APPOINTMENT ==========
export type AppointmentStatus = 'scheduled' | 'completed' | 'cancelled';

export interface Appointment {
  id: number;
  patient_id: number;
  doctor_id: number;
  date: string;
  time: string;
  status: AppointmentStatus;
  reason?: string;
  // Campos para UI (AGREGADOS)
  doctor_name?: string;    // Para línea 306, 384
  specialty?: string;      // Para línea 308, 385
  doctor?: Doctor;
}

// ========== NOTIFICATION ==========
export type NotificationType = 'appointment' | 'appointment_created' | 'system' | 'alert' | 'reminder';

export interface Notification {
  id: number;
  user_id: number;
  type: NotificationType;  // CORREGIDO: Incluye alert y reminder
  title: string;
  message: string;
  read: boolean;
  // Campo alias para compatibilidad (AGREGADO)
  is_read?: boolean;      // Para código que usa is_read
  created_at: string;
}

// ========== API RESPONSE ==========
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}
