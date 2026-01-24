import React, { useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import "./Sidebar.css";

// Iconos profesionales
const IconHome = () => <span className="sidebar-icon">📊</span>;
const IconDoctors = () => <span className="sidebar-icon">👨‍⚕️</span>;
const IconAppointments = () => <span className="sidebar-icon">📅</span>;
const IconNotifications = () => <span className="sidebar-icon">🔔</span>;
const IconSettings = () => <span className="sidebar-icon">⚙️</span>;
const IconLogout = () => <span className="sidebar-icon">🚪</span>;
const IconChevron = () => <span className="chevron">›</span>;

const Sidebar: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);

  const menuItems = [
    { path: "/dashboard", label: "Dashboard", icon: <IconHome />, badge: null },
    { path: "/doctors", label: "Doctores", icon: <IconDoctors />, badge: null },
    { path: "/appointments", label: "Citas", icon: <IconAppointments />, badge: "31+" },
    { path: "/notifications", label: "Notificaciones", icon: <IconNotifications />, badge: "8" },
    { path: "/settings", label: "Configuración", icon: <IconSettings />, badge: null },
  ];

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  // Obtener iniciales del usuario de forma segura
  const getUserInitials = () => {
    if (user?.name) {
      const names = user.name.split(' ');
      if (names.length >= 2) {
        return (names[0].charAt(0) + names[1].charAt(0)).toUpperCase();
      }
      return user.name.charAt(0).toUpperCase();
    }
    return "U";
  };

  // Obtener nombre seguro (sin correo)
  const getDisplayName = () => {
    if (user?.name) {
      // Mostrar solo el nombre, sin apellidos completos
      const names = user.name.split(' ');
      return names[0]; // Solo primer nombre
    }
    return "Usuario";
  };

  return (
    <div className={`sidebar ${collapsed ? "collapsed" : ""}`}>
      {/* Logo y Toggle */}
      <div className="sidebar-header">
        <div className="logo-container" onClick={() => navigate("/dashboard")}>
          <div className="logo-icon">🏥</div>
          {!collapsed && (
            <div className="logo-text">
              <h2>HDuce</h2>
              <p className="logo-subtitle">Medical Suite</p>
            </div>
          )}
        </div>
        <button 
          className="sidebar-toggle" 
          onClick={() => setCollapsed(!collapsed)}
          title={collapsed ? "Expandir menú" : "Contraer menú"}
          aria-label={collapsed ? "Expandir menú" : "Contraer menú"}
        >
          <IconChevron />
        </button>
      </div>

      {/* User Profile - Sin información sensible */}
      <div className="user-profile">
        <div className="user-avatar" title={`${getDisplayName()}`}>
          {getUserInitials()}
        </div>
        {!collapsed && (
          <div className="user-info">
            <h4 className="user-name">{getDisplayName()}</h4>
            <p className="user-role">Usuario Premium</p>
            <div className="user-status">
              <span className="status-dot online"></span>
              <span>Conectado</span>
            </div>
          </div>
        )}
      </div>

      {/* Navigation Menu */}
      <nav className="sidebar-nav" aria-label="Navegación principal">
        <div className="nav-section">
          {!collapsed && <h3 className="nav-section-title">Navegación Principal</h3>}
          <ul className="nav-menu">
            {menuItems.map((item) => (
              <li key={item.path}>
                <NavLink
                  to={item.path}
                  className={({ isActive }) =>
                    `nav-link ${isActive ? "active" : ""}`
                  }
                  title={collapsed ? item.label : ""}
                  aria-label={item.label}
                >
                  <span className="nav-icon">{item.icon}</span>
                  {!collapsed && (
                    <>
                      <span className="nav-label">{item.label}</span>
                      {item.badge && <span className="nav-badge">{item.badge}</span>}
                    </>
                  )}
                  {!collapsed && <IconChevron />}
                </NavLink>
              </li>
            ))}
          </ul>
        </div>

        {!collapsed && (
          <div className="nav-section quick-actions">
            <h3 className="nav-section-title">Acciones Rápidas</h3>
            <div className="quick-actions-grid">
              <button className="quick-action-btn" onClick={() => navigate("/appointments?new=true")}>
                <span>➕</span>
                <span>Nueva Cita</span>
              </button>
              <button className="quick-action-btn" onClick={() => navigate("/doctors?search=true")}>
                <span>🔍</span>
                <span>Buscar Doctor</span>
              </button>
            </div>
          </div>
        )}
      </nav>

      {/* Footer with Logout */}
      <div className="sidebar-footer">
        <button
          className="logout-btn"
          onClick={handleLogout}
          title={collapsed ? "Cerrar Sesión" : ""}
          aria-label="Cerrar sesión"
        >
          <IconLogout />
          {!collapsed && <span>Cerrar Sesión</span>}
        </button>
        {!collapsed && (
          <div className="sidebar-info">
            <p className="app-version">v2.1.0 • HDuce Medical</p>
            <p className="privacy-notice">
              <small>🔒 Tus datos están protegidos</small>
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Sidebar;
