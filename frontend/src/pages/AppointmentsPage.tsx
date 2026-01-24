import React, { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import endpoints from '../services/endpoints';
import { Appointment } from '../types/hduce';
import './AppointmentsPage.css';

const AppointmentsPage: React.FC = () => {
  const { isAuthenticated, isLoading, user } = useAuth();
  const navigate = useNavigate();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [userAppointments, setUserAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>('all');
  const [filterDate, setFilterDate] = useState<string>('');

  useEffect(() => {
    if (!isAuthenticated && !isLoading) {
      navigate('/login');
      return;
    }
    if (isAuthenticated) {
      fetchAppointments();
    }
  }, [isAuthenticated, isLoading, navigate]);

  const fetchAppointments = async () => {
    try {
      setLoading(true);
      const response = await api.get(endpoints.appointments.list);
      const appointmentsData = response.data;
      setAppointments(appointmentsData);
      
      // Filter for current user (simulated - in real app would be by user_id)
      const userApps = appointmentsData.filter((apt: Appointment, index: number) => index % 3 === 0);
      setUserAppointments(userApps);
      
      setError(null);
    } catch (err) {
      console.error('Error fetching appointments:', err);
      setError('Failed to load appointments. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const getFilteredAppointments = () => {
    let filtered = userAppointments;

    if (filterStatus !== 'all') {
      filtered = filtered.filter(apt => apt.status === filterStatus);
    }

    if (filterDate) {
      const selectedDate = new Date(filterDate).toDateString();
      filtered = filtered.filter(apt => 
        new Date(apt.date).toDateString() === selectedDate
      );
    }

    return filtered;
  };

  const getUpcomingAppointments = () => {
    const today = new Date();
    return userAppointments
      .filter(apt => apt.status === 'scheduled' && new Date(apt.date) >= today)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
      .slice(0, 3);
  };

  const getStats = () => {
    const scheduled = userAppointments.filter(a => a.status === 'scheduled').length;
    const completed = userAppointments.filter(a => a.status === 'completed').length;
    const cancelled = userAppointments.filter(a => a.status === 'cancelled').length;
    const total = userAppointments.length;
    
    return { scheduled, completed, cancelled, total };
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  };

  const formatTime = (timeString: string) => {
    return timeString; // Assuming time is already in HH:MM format
  };

  const handleStatusChange = async (id: number, newStatus: string) => {
    try {
      // In a real app, this would be a PUT request
      setUserAppointments(prev =>
        prev.map(apt =>
          apt.id === id ? { ...apt, status: newStatus as AppointmentStatus } : apt
        )
      );
      
      // Show success message
      alert(`Appointment ${newStatus} successfully`);
    } catch (err) {
      console.error('Error updating appointment:', err);
      alert('Failed to update appointment');
    }
  };

  if (isLoading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  if (!isAuthenticated) {
    navigate('/login');
    return null;
  }

  const stats = getStats();
  const filteredAppointments = getFilteredAppointments();
  const upcomingAppointments = getUpcomingAppointments();

  return (
    <div className="appointments-page">
      {/* Header */}
      <div className="page-header">
        <div className="header-top">
          <div className="page-title">
            <h1>Appointments</h1>
            <p>Manage your medical appointments and schedule new ones</p>
          </div>
          
          <div className="header-actions">
            <button 
              className="new-appointment-btn"
              onClick={() => navigate('/doctors')}
            >
              <span>+</span> Schedule New Appointment
            </button>
          </div>
        </div>
        
        <div className="user-greeting">
          Welcome back, <strong>{user?.name}</strong>! Here are your appointments.
        </div>
      </div>

      {/* Stats Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon">??</div>
          <div className="stat-content">
            <h3>Total Appointments</h3>
            <div className="stat-number">{stats.total}</div>
            <div className="stat-change positive">
              <span>?</span> {stats.scheduled} upcoming
            </div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">?</div>
          <div className="stat-content">
            <h3>Completed</h3>
            <div className="stat-number">{stats.completed}</div>
            <div className="stat-change positive">
              <span>?</span> {Math.round((stats.completed / stats.total) * 100)}% completion rate
            </div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">?</div>
          <div className="stat-content">
            <h3>Scheduled</h3>
            <div className="stat-number">{stats.scheduled}</div>
            <div className="stat-change">
              <span>?</span> Next: {upcomingAppointments.length > 0 ? formatDate(upcomingAppointments[0].date) : 'None'}
            </div>
          </div>
        </div>
        
        <div className="stat-card">
          <div className="stat-icon">?</div>
          <div className="stat-content">
            <h3>Cancelled</h3>
            <div className="stat-number">{stats.cancelled}</div>
            <div className="stat-change negative">
              <span>?</span> {Math.round((stats.cancelled / stats.total) * 100)}% cancellation rate
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="filters-bar">
        <div className="filter-group">
          <label>Filter by Status</label>
          <select 
            className="filter-select"
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
          >
            <option value="all">All Statuses</option>
            <option value="scheduled">Scheduled</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
          </select>
        </div>
        
        <div className="filter-group">
          <label>Filter by Date</label>
          <input
            type="date"
            className="filter-select"
            value={filterDate}
            onChange={(e) => setFilterDate(e.target.value)}
          />
        </div>
        
        <button 
          className="filter-btn"
          onClick={() => {
            setFilterStatus('all');
            setFilterDate('');
          }}
        >
          Clear Filters
        </button>
      </div>

      {/* Appointments Table */}
      <div className="appointments-container">
        <div className="table-header">
          <h2>Your Appointments ({filteredAppointments.length})</h2>
          <div className="table-actions">
            <button className="table-btn view" onClick={fetchAppointments}>
              Refresh
            </button>
          </div>
        </div>
        
        {loading ? (
          <div className="loading-skeleton">
            {[1, 2, 3].map(i => (
              <div key={i} className="skeleton-row"></div>
            ))}
          </div>
        ) : error ? (
          <div className="empty-appointments">
            <div className="empty-icon">??</div>
            <h3>Unable to Load Appointments</h3>
            <p>{error}</p>
            <button onClick={fetchAppointments} className="action-btn primary">
              Retry
            </button>
          </div>
        ) : filteredAppointments.length === 0 ? (
          <div className="empty-appointments">
            <div className="empty-icon">??</div>
            <h3>No Appointments Found</h3>
            <p>
              {userAppointments.length === 0 
                ? "You don't have any appointments yet. Schedule your first appointment!"
                : "No appointments match your current filters. Try changing your filter criteria."}
            </p>
            {userAppointments.length === 0 && (
              <button 
                className="new-appointment-btn"
                onClick={() => navigate('/doctors')}
              >
                Schedule Your First Appointment
              </button>
            )}
          </div>
        ) : (
          <table className="appointments-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Time</th>
                <th>Doctor</th>
                <th>Specialty</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredAppointments.map((appointment) => (
                <tr key={appointment.id}>
                  <td>
                    <strong>{formatDate(appointment.date)}</strong>
                  </td>
                  <td>
                    <span className="time-badge">{formatTime(appointment.time)}</span>
                  </td>
                  <td>{appointment.doctor_name}</td>
                  <td>
                    <span className="specialty-badge">{appointment.specialty}</span>
                  </td>
                  <td>
                    <span className={`status-badge ${appointment.status}`}>
                      {appointment.status}
                    </span>
                  </td>
                  <td className="action-cell">
                    <button 
                      className="table-btn view"
                      onClick={() => alert(`Viewing appointment ${appointment.id}`)}
                    >
                      View
                    </button>
                    
                    {appointment.status === 'scheduled' && (
                      <>
                        <button 
                          className="table-btn reschedule"
                          onClick={() => alert(`Reschedule appointment ${appointment.id}`)}
                        >
                          Reschedule
                        </button>
                        <button 
                          className="table-btn cancel"
                          onClick={() => {
                            if (window.confirm('Are you sure you want to cancel this appointment?')) {
                              handleStatusChange(appointment.id, 'cancelled');
                            }
                          }}
                        >
                          Cancel
                        </button>
                      </>
                    )}
                    
                    {appointment.status === 'completed' && (
                      <button className="table-btn view" disabled>
                        Completed
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Upcoming Appointments */}
      {upcomingAppointments.length > 0 && (
        <div className="upcoming-section">
          <div className="upcoming-header">
            <h2>Upcoming Appointments</h2>
            <span className="badge">{upcomingAppointments.length} upcoming</span>
          </div>
          
          <div className="upcoming-cards">
            {upcomingAppointments.map((appointment) => {
              const appointmentDate = new Date(appointment.date);
              const today = new Date();
              const isToday = appointmentDate.toDateString() === today.toDateString();
              const isTomorrow = new Date(today.setDate(today.getDate() + 1)).toDateString() === appointmentDate.toDateString();
              
              return (
                <div 
                  key={appointment.id} 
                  className={`upcoming-card ${isToday ? 'urgent' : ''}`}
                >
                  <div className="upcoming-date">
                    <span className="date-badge">
                      {isToday ? 'TODAY' : isTomorrow ? 'TOMORROW' : formatDate(appointment.date)}
                    </span>
                    <span className="time">{formatTime(appointment.time)}</span>
                  </div>
                  
                  <h4>Appointment with Dr. {appointment.doctor_name}</h4>
                  <p>Specialty: {appointment.specialty}</p>
                  
                  <div className="upcoming-actions">
                    <button 
                      className="action-btn view"
                      onClick={() => alert(`Viewing appointment ${appointment.id}`)}
                    >
                      View Details
                    </button>
                    
                    {!isToday && (
                      <button 
                        className="action-btn cancel"
                        onClick={() => {
                          if (window.confirm('Are you sure you want to cancel this appointment?')) {
                            handleStatusChange(appointment.id, 'cancelled');
                          }
                        }}
                      >
                        Cancel
                      </button>
                    )}
                    
                    {isToday && (
                      <button 
                        className="action-btn primary"
                        onClick={() => alert('Join video call or check in')}
                      >
                        Join Appointment
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Footer */}
      <div className="page-footer">
        <p>
          Showing {filteredAppointments.length} of {userAppointments.length} appointments
          {filterStatus !== 'all' && ` (filtered by: ${filterStatus})`}
        </p>
        <div className="footer-actions">
          <button onClick={fetchAppointments} className="action-btn">
            Refresh List
          </button>
          <button 
            onClick={() => navigate('/doctors')}
            className="action-btn primary"
          >
            Book New Appointment
          </button>
        </div>
      </div>
    </div>
  );
};

export default AppointmentsPage;


