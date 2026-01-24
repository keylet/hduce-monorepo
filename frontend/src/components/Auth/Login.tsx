import React, { useState } from 'react';
import { useAuth } from '../../context/AuthContext';
import './Login.css';

interface LoginProps {
  onLoginSuccess?: () => void;
  onError?: (error: string) => void;
}

const Login: React.FC<LoginProps> = ({ onLoginSuccess, onError }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { login } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    console.log('[Login] Attempting login for:', email);

    try {
      await login(email, password);
      console.log('[Login] Successful!');
      if (onLoginSuccess) {
        onLoginSuccess();
      }
    } catch (err: any) {
      console.error('[Login] Error:', err);
      const errorMessage = err.message || 'Login failed. Please check your credentials.';
      setError(errorMessage);
      if (onError) {
        onError(errorMessage);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const useDemoCredentials = () => {
    setEmail('testuser@example.com');
    setPassword('secret');
  };

  return (
    <div className="login-container">
      {/* Left Panel - Login Form */}
      <div className="login-form-panel">
        <div className="login-card">
          {/* Header */}
          <div className="login-header">
            <div className="logo-container">
              <div className="logo-icon">🏥</div>
              <div className="logo-text">
                <h1>HDuce Medical</h1>
                <p className="subtitle">Healthcare Management System</p>
              </div>
            </div>
            <p className="welcome-text">Sign in to your account</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="login-form">
            <div className="form-group">
              <label htmlFor="email" className="form-label">
                <span className="label-icon">📧</span>
                Email Address
              </label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="form-input"
                placeholder="your.email@example.com"
                required
                disabled={isLoading}
                autoComplete="username"
              />
            </div>

            <div className="form-group">
              <label htmlFor="password" className="form-label">
                <span className="label-icon">🔒</span>
                Password
              </label>
              <input
                type="password"
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="form-input"
                placeholder="Enter your password"
                required
                disabled={isLoading}
                autoComplete="current-password"
              />
            </div>

            {/* Error Message */}
            {error && (
              <div className="error-message">
                <span className="error-icon">⚠️</span>
                <span className="error-text">{error}</span>
              </div>
            )}

            {/* Submit Button */}
            <button 
              type="submit" 
              className="login-button"
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <span className="button-spinner"></span>
                  Signing In...
                </>
              ) : (
                'Sign In'
              )}
            </button>

            {/* Demo Credentials Section */}
            <div className="demo-section">
              <button 
                type="button" 
                className="demo-button"
                onClick={useDemoCredentials}
                disabled={isLoading}
              >
                <span className="demo-icon">🧪</span>
                Use Demo Credentials
              </button>
              
              <div className="demo-info">
                <p className="demo-title">Test Account Details:</p>
                <div className="demo-credentials">
                  <div className="credential-row">
                    <span className="credential-label">Email:</span>
                    <code className="credential-value">testuser@example.com</code>
                  </div>
                  <div className="credential-row">
                    <span className="credential-label">Password:</span>
                    <code className="credential-value">secret</code>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer Links */}
            <div className="form-footer">
              <a href="/forgot-password" className="footer-link">Forgot Password?</a>
              <span className="separator">•</span>
              <a href="/support" className="footer-link">Need Help?</a>
            </div>
          </form>
        </div>
      </div>

      {/* Right Panel - Information */}
      <div className="info-panel">
        <div className="info-content">
          <h2 className="info-title">Welcome to HDuce Medical</h2>
          <p className="info-subtitle">Your comprehensive healthcare management platform</p>
          
          {/* Features List */}
          <div className="features-grid">
            <div className="feature-card">
              <div className="feature-icon">✅</div>
              <div className="feature-content">
                <h4>Secure Access</h4>
                <p>JWT authentication with industry-standard encryption</p>
              </div>
            </div>
            
            <div className="feature-card">
              <div className="feature-icon">👨‍⚕️</div>
              <div className="feature-content">
                <h4>Medical Specialists</h4>
                <p>Access to 5 medical specialties and doctors</p>
              </div>
            </div>
            
            <div className="feature-card">
              <div className="feature-icon">📱</div>
              <div className="feature-content">
                <h4>Cross-Platform</h4>
                <p>Responsive design for all devices</p>
              </div>
            </div>
            
            <div className="feature-card">
              <div className="feature-icon">🔔</div>
              <div className="feature-content">
                <h4>Real-time Notifications</h4>
                <p>Stay updated with appointment reminders</p>
              </div>
            </div>
          </div>

          {/* System Statistics */}
          <div className="stats-section">
            <h3 className="stats-title">System Status</h3>
            <div className="stats-grid">
              <div className="stat-item">
                <span className="stat-number">5</span>
                <span className="stat-label">Active Doctors</span>
              </div>
              <div className="stat-item">
                <span className="stat-number">31+</span>
                <span className="stat-label">Appointments</span>
              </div>
              <div className="stat-item">
                <span className="stat-number">8</span>
                <span className="stat-label">Notifications</span>
              </div>
            </div>
          </div>

          {/* Security Notice */}
          <div className="security-notice">
            <div className="security-icon">🛡️</div>
            <div className="security-content">
              <h4>Your Security is Our Priority</h4>
              <p>All data is encrypted and protected according to healthcare standards</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
