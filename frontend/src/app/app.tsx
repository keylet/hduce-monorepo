import React from "react";
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "../context/AuthContext";
import ProtectedRoute from "../components/ProtectedRoute";

// Importar páginas
import LoginPage from "../pages/LoginPage";
import DashboardPage from "../pages/DashboardPage";
import DoctorsPage from "../pages/DoctorsPage";
import AppointmentsPage from "../pages/AppointmentsPage";
import NotificationsPage from "../pages/NotificationsPage";

// Componentes de layout
import Sidebar from "../components/Sidebar";
import Header from "../components/Header";

// Estilos globales
import "./App.css";

function App() {
  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AuthProvider>
        <Routes>
          {/* Ruta pública - Login */}
          <Route path="/login" element={<LoginPage />} />
          
          {/* Rutas protegidas */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <div className="app-layout">
                  <Sidebar />
                  <div className="main-content">
                    <Header />
                    <DashboardPage />
                  </div>
                </div>
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/doctors"
            element={
              <ProtectedRoute>
                <div className="app-layout">
                  <Sidebar />
                  <div className="main-content">
                    <Header />
                    <DoctorsPage />
                  </div>
                </div>
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/appointments"
            element={
              <ProtectedRoute>
                <div className="app-layout">
                  <Sidebar />
                  <div className="main-content">
                    <Header />
                    <AppointmentsPage />
                  </div>
                </div>
              </ProtectedRoute>
            }
          />
          
          <Route
            path="/notifications"
            element={
              <ProtectedRoute>
                <div className="app-layout">
                  <Sidebar />
                  <div className="main-content">
                    <Header />
                    <NotificationsPage />
                  </div>
                </div>
              </ProtectedRoute>
            }
          />
          
          {/* Redirección por defecto */}
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
          
          {/* 404 - Not Found */}
          <Route path="*" element={<div className="not-found">Página no encontrada</div>} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;

