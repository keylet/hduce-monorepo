import React from 'react';
import { useAuth } from '../../context/AuthContext';
import './Dashboard.css';

interface DashboardProps {
  onLogout?: () => void;
}

const Dashboard: React.FC<DashboardProps> = ({ onLogout }) => {
  const { user, isAuthenticated, logout } = useAuth();
  
  if (!isAuthenticated || !user) {
    return (
      <div className="dashboard-container">
        <div className="unauthorized-message">
          <h2>Access Denied</h2>
          <p>Please sign in to access the dashboard</p>
          <a href="/login" className="login-redirect-btn">Go to Login</a>
        </div>
      </div>
    );
  }
  
  const handleLogout = () => {
    logout();
    if (onLogout) {
      onLogout();
    }
    window.location.href = '/login';
  };
  
  return (
    <div className="dashboard-container">
      {/* Header */}
      <header className="dashboard-header">
        <div className="header-content">
          <div className="brand-section">
            <div className="brand-logo">🏥</div>
            <div className="brand-text">
              <h1>HDuce Medical</h1>
              <p className="brand-subtitle">Healthcare Management Dashboard</p>
            </div>
          </div>
          
          <div className="user-section">
            <div className="user-info">
              <div className="user-avatar">
                {user.name.charAt(0).toUpperCase()}
              </div>
              <div className="user-details">
                <span className="user-name">{user.name}</span>
                <span className="user-email">{user.email}</span>
              </div>
            </div>
            <button onClick={handleLogout} className="logout-btn">
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="dashboard-main">
        {/* Welcome Section */}
        <section className="welcome-section">
          <div className="welcome-card">
            <div className="welcome-content">
              <h2>Welcome back, {user.name}! 👋</h2>
              <p>Your healthcare management portal is ready. Here's what you can do today.</p>
            </div>
            <div className="welcome-stats">
              <div className="stat-badge">
                <span className="stat-number">5</span>
                <span className="stat-label">Doctors Available</span>
              </div>
              <div className="stat-badge">
                <span className="stat-number">31+</span>
                <span className="stat-label">Appointments</span>
              </div>
              <div className="stat-badge">
                <span className="stat-number">8</span>
                <span className="stat-label">Notifications</span>
              </div>
            </div>
          </div>
        </section>

        {/* Dashboard Grid */}
        <div className="dashboard-grid">
          {/* User Profile Card */}
          <div className="dashboard-card profile-card">
            <div className="card-header">
              <h3 className="card-title">
                <span className="card-icon">👤</span>
                User Profile
              </h3>
            </div>
            <div className="card-content">
              <div className="profile-details">
                <div className="detail-item">
                  <span className="detail-label">Full Name</span>
                  <span className="detail-value">{user.name}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Email Address</span>
                  <span className="detail-value">{user.email}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">User ID</span>
                  <span className="detail-value badge id-badge">#{user.id}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Age</span>
                  <span className="detail-value">{user.age || 'Not specified'}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Account Role</span>
                  <span className="detail-value badge role-badge">Patient</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Account Status</span>
                  <span className="detail-value badge status-badge active">Active</span>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Actions Card */}
          <div className="dashboard-card actions-card">
            <div className="card-header">
              <h3 className="card-title">
                <span className="card-icon">🚀</span>
                Quick Actions
              </h3>
            </div>
            <div className="card-content">
              <div className="actions-grid">
                <a href="/doctors" className="action-item doctor-action">
                  <div className="action-icon">👨‍⚕️</div>
                  <div className="action-content">
                    <h4>View Doctors</h4>
                    <p>Browse available specialists</p>
                  </div>
                  <div className="action-arrow">→</div>
                </a>
                
                <a href="/appointments" className="action-item appointment-action">
                  <div className="action-icon">📅</div>
                  <div className="action-content">
                    <h4>My Appointments</h4>
                    <p>Manage medical appointments</p>
                  </div>
                  <div className="action-arrow">→</div>
                </a>
                
                <a href="/notifications" className="action-item notification-action">
                  <div className="action-icon">🔔</div>
                  <div className="action-content">
                    <h4>Notifications</h4>
                    <p>View alerts and reminders</p>
                  </div>
                  <div className="action-arrow">→</div>
                </a>
                
                <button className="action-item profile-action">
                  <div className="action-icon">⚙️</div>
                  <div className="action-content">
                    <h4>Update Profile</h4>
                    <p>Edit personal information</p>
                  </div>
                  <div className="action-arrow">→</div>
                </button>
              </div>
            </div>
          </div>

          {/* System Status Card */}
          <div className="dashboard-card status-card">
            <div className="card-header">
              <h3 className="card-title">
                <span className="card-icon">📊</span>
                System Status
              </h3>
            </div>
            <div className="card-content">
              <div className="status-list">
                <div className="status-item status-active">
                  <span className="status-indicator"></span>
                  <div className="status-content">
                    <span className="status-title">Authentication</span>
                    <span className="status-description">Session active</span>
                  </div>
                </div>
                <div className="status-item status-active">
                  <span className="status-indicator"></span>
                  <div className="status-content">
                    <span className="status-title">Medical Services</span>
                    <span className="status-description">All systems operational</span>
                  </div>
                </div>
                <div className="status-item status-active">
                  <span className="status-indicator"></span>
                  <div className="status-content">
                    <span className="status-title">Database Connection</span>
                    <span className="status-description">Stable connection</span>
                  </div>
                </div>
                <div className="status-item status-info">
                  <span className="status-indicator"></span>
                  <div className="status-content">
                    <span className="status-title">Doctors Online</span>
                    <span className="status-description">5 specialists available</span>
                  </div>
                </div>
                <div className="status-item status-info">
                  <span className="status-indicator"></span>
                  <div className="status-content">
                    <span className="status-title">Appointments</span>
                    <span className="status-description">31+ scheduled</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Next Steps Card */}
          <div className="dashboard-card steps-card">
            <div className="card-header">
              <h3 className="card-title">
                <span className="card-icon">📝</span>
                Recommended Next Steps
              </h3>
            </div>
            <div className="card-content">
              <ol className="steps-list">
                <li>
                  <strong>Browse available doctors</strong> by specialty to find the right specialist for your needs.
                </li>
                <li>
                  <strong>Schedule a medical appointment</strong> based on doctor availability and your preferences.
                </li>
                <li>
                  <strong>Check your notifications</strong> regularly for appointment reminders and updates.
                </li>
                <li>
                  <strong>Complete your medical profile</strong> with relevant health information for better care.
                </li>
                <li>
                  <strong>Explore medical specialties</strong> offered by our healthcare platform.
                </li>
              </ol>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="dashboard-footer">
        <div className="footer-content">
          <div className="footer-info">
            <p>HDuce Medical Platform v1.0 • Healthcare Management System</p>
            <p className="footer-copyright">© 2024 HDuce Medical. All rights reserved.</p>
          </div>
          <div className="footer-links">
            <a href="/help" className="footer-link">Help Center</a>
            <a href="/privacy" className="footer-link">Privacy Policy</a>
            <a href="/terms" className="footer-link">Terms of Service</a>
            <a href="/contact" className="footer-link">Contact Support</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Dashboard;
