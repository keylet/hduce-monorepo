// frontend/src/types/hduce.ts

export interface User {
  id: number;
  email: string;
  username: string;
  name?: string;
  age?: number;
  role: 'patient' | 'doctor' | 'admin';
  created_at?: string;
}

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
  specialty: Specialty | string;  // Puede ser objeto o string
  available?: boolean;            // Campo opcional para UI
  available_days?: string[];      // Campo opcional para UI
  available_hours?: string;       // Campo opcional para UI
}

export interface Appointment {
  id: number;
  patient_id: number;
  doctor_id: number;
  date: string;
  time: string;
  status: 'scheduled' | 'completed' | 'cancelled';
  reason?: string;
  doctor?: Doctor;
}

export interface Notification {
  id: number;
  user_id: number;
  type: 'appointment' | 'appointment_created' | 'system';
  title: string;
  message: string;
  read: boolean;
  created_at: string;
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

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

export interface DecodedToken {
  sub: string;
  email: string;
  username: string;
  user_id: number;
  exp: number;
  iat: number;
}
