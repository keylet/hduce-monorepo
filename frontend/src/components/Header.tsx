import React, { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";
import "./Header.css";

const Header: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [currentTime, setCurrentTime] = useState("");
  const [isProfileOpen, setIsProfileOpen] = useState(false);

  // Actualizar hora cada minuto
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const options: Intl.DateTimeFormatOptions = {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      };
      setCurrentTime(now.toLocaleDateString('es-ES', options));
    };
    
    updateTime();
    const interval = setInterval(updateTime, 60000);
    return () => clearInterval(interval);
  }, []);

  const handleLogout = () => {
    logout();
    navigate("/login");
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return "Buenos días";
    if (hour < 18) return "Buenas tardes";
    return "Buenas noches";
  };

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

  const getDisplayName = () => {
    if (user?.name) {
      const names = user.name.split(' ');
      return names[0]; // Solo primer nombre
    }
    return "Usuario";
  };

  return (
    <header className="professional-header">
      <div className="header-container">
        {/* Left: Logo and Time */}
        <div className="header-left">
          <div className="logo" onClick={() => navigate("/dashboard")}>
            <div className="logo-icon">🏥</div>
            <div className="logo-text">
              <h1 className="logo-title">HDuce Medical</h1>
              <p className="logo-subtitle">Healthcare Management</p>
            </div>
          </div>
          
          <div className="time-display">
            <span className="time-icon">🕒</span>
            <div className="time-info">
              <p className="current-date">{currentTime}</p>
              <p className="greeting">{getGreeting()}!</p>
            </div>
          </div>
        </div>

        {/* Right: User Profile and Actions */}
        <div className="header-right">
          {/* Quick Stats */}
          <div className="header-stats">
            <div className="stat-item">
              <span className="stat-icon">👨‍⚕️</span>
              <div className="stat-info">
                <span className="stat-number">5</span>
                <span className="stat-label">Doctores</span>
              </div>
            </div>
            <div className="stat-item">
              <span className="stat-icon">📅</span>
              <div className="stat-info">
                <span className="stat-number">31+</span>
                <span className="stat-label">Citas</span>
              </div>
            </div>
            <div className="stat-item">
              <span className="stat-icon">🔔</span>
              <div className="stat-info">
                <span className="stat-number">8</span>
                <span className="stat-label">Alertas</span>
              </div>
            </div>
          </div>

          {/* User Profile Dropdown */}
          <div className="user-profile-container">
            <button 
              className="profile-toggle"
              onClick={() => setIsProfileOpen(!isProfileOpen)}
              aria-label="Abrir menú de perfil"
              aria-expanded={isProfileOpen}
            >
              <div className="user-avatar" title={`${getDisplayName()}`}>
                {getUserInitials()}
              </div>
              <div className="user-info-mini">
                <span className="user-name-mini">{getDisplayName()}</span>
                <span className="user-status">🟢 Conectado</span>
              </div>
              <span className="dropdown-arrow">{isProfileOpen ? "▲" : "▼"}</span>
            </button>

            {isProfileOpen && (
              <div className="profile-dropdown">
                <div className="dropdown-header">
                  <div className="dropdown-avatar">{getUserInitials()}</div>
                  <div className="dropdown-user-info">
                    <h4>{getDisplayName()}</h4>
                    <p>Usuario Premium</p>
                    <small>ID: {user?.id ? `#${user.id.toString().padStart(6, '0')}` : 'N/A'}</small>
                  </div>
                </div>
                
                <div className="dropdown-divider"></div>
                
                <div className="dropdown-menu">
                  <button className="dropdown-item" onClick={() => navigate("/profile")}>
                    <span>👤</span> Mi Perfil
                  </button>
                  <button className="dropdown-item" onClick={() => navigate("/settings")}>
                    <span>⚙️</span> Configuración
                  </button>
                  <button className="dropdown-item" onClick={() => navigate("/help")}>
                    <span>❓</span> Ayuda & Soporte
                  </button>
                  
                  <div className="dropdown-divider"></div>
                  
                  <button className="dropdown-item logout" onClick={handleLogout}>
                    <span>🚪</span> Cerrar Sesión
                  </button>
                </div>
                
                <div className="dropdown-footer">
                  <small>HDuce Medical v2.1.0</small>
                  <small>🔒 Sesión segura</small>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
