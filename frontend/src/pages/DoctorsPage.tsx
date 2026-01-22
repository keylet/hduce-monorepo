import React, { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import endpoints from '../services/endpoints';
import { Doctor } from '../types/hduce';
import './DoctorsPage.css';

const DoctorsPage: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();
  const navigate = useNavigate();
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [filteredDoctors, setFilteredDoctors] = useState<Doctor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedSpecialty, setSelectedSpecialty] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');

  const specialties = ['All', 'Cardiología', 'Dermatología', 'Pediatría', 'Neurología', 'Ortopedia'];

  // Helper function to get specialty name (handles both string and object)
  const getSpecialtyName = (doctor: Doctor): string => {
    if (!doctor.specialty) return 'No specialty';
    if (typeof doctor.specialty === 'string') return doctor.specialty;
    if (typeof doctor.specialty === 'object' && doctor.specialty !== null) {
      return doctor.specialty.name || 'No specialty';
    }
    return 'No specialty';
  };

  useEffect(() => {
    if (!isAuthenticated && !isLoading) {
      navigate('/login');
      return;
    }
    if (isAuthenticated) {
      fetchDoctors();
    }
  }, [isAuthenticated, isLoading, navigate]);

  const fetchDoctors = async () => {
    try {
      setLoading(true);
      const response = await api.get(endpoints.doctors.list);
      const doctorsData = response.data;
      setDoctors(doctorsData);
      setFilteredDoctors(doctorsData);
      setError(null);
    } catch (err) {
      console.error('Error fetching doctors:', err);
      setError('Failed to load doctors. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    let result = doctors;

    // Filter by specialty
    if (selectedSpecialty !== 'all') {
      result = result.filter(doctor =>
        getSpecialtyName(doctor).toLowerCase() === selectedSpecialty.toLowerCase()
      );
    }

    // Filter by search term
    if (searchTerm) {
      result = result.filter(doctor =>
        doctor.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        getSpecialtyName(doctor).toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredDoctors(result);
  }, [doctors, selectedSpecialty, searchTerm]);

  const handleSpecialtyFilter = (specialty: string) => {
    setSelectedSpecialty(specialty.toLowerCase());
  };

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

  const getAvailableDays = (doctor: Doctor) => {
    if (!doctor.available_days || doctor.available_days.length === 0) {
      return 'Check availability';
    }
    return doctor.available_days.slice(0, 3).join(', ') + (doctor.available_days.length > 3 ? '...' : '');
  };

  const getAvailableHours = (doctor: Doctor) => {
    if (!doctor.available_hours || doctor.available_hours.length === 0) {
      return 'N/A';
    }
    return doctor.available_hours;
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

  // Use is_active instead of available (since available doesn't exist in API)
  const availableCount = doctors.filter(d => d.is_active).length;
  const totalSpecialties = [...new Set(doctors.map(d => getSpecialtyName(d)))].length;

  return (
    <div className="doctors-page">
      {/* Header Section */}
      <div className="doctors-header">
        <div className="header-title">
          <h1>Medical Specialists</h1>
          <p>Browse and book appointments with our expert doctors</p>
        </div>

        <div className="header-stats">
          <div className="stat-box">
            <div className="stat-number">{doctors.length}</div>
            <div className="stat-label">Total Doctors</div>
          </div>
          <div className="stat-box">
            <div className="stat-number">{availableCount}</div>
            <div className="stat-label">Available Now</div>
          </div>
          <div className="stat-box">
            <div className="stat-number">{totalSpecialties}</div>
            <div className="stat-label">Specialties</div>
          </div>
        </div>
      </div>

      {/* Filters Section */}
      <div className="filters-section">
        <div className="filters-title">
          <h2>Filter by Specialty</h2>
          <div className="search-container">
            <input
              type="text"
              placeholder="Search doctors..."
              className="search-input"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <span className="search-icon">🔍</span>
          </div>
        </div>

        <div className="specialty-filters">
          {specialties.map((specialty) => (
            <button
              key={specialty}
              className={`filter-btn ${selectedSpecialty === specialty.toLowerCase() ? 'active' : ''}`}
              onClick={() => handleSpecialtyFilter(specialty)}
            >
              {specialty}
            </button>
          ))}
        </div>
      </div>

      {/* Doctors Grid */}
      {loading ? (
        <div className="loading-container">
          <div className="loading-spinner"></div>
          <p>Loading doctors...</p>
        </div>
      ) : error ? (
        <div className="empty-state">
          <div className="empty-icon">😕</div>
          <h3>Unable to Load Doctors</h3>
          <p>{error}</p>
          <button onClick={fetchDoctors} className="action-btn primary">
            Retry
          </button>
        </div>
      ) : filteredDoctors.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon">👨‍⚕️</div>
          <h3>No Doctors Found</h3>
          <p>Try adjusting your filters or search term</p>
        </div>
      ) : (
        <>
          <div className="results-info">
            <p>Showing {filteredDoctors.length} of {doctors.length} doctors</p>
          </div>

          <div className="doctors-grid">
            {filteredDoctors.map((doctor) => (
              <div key={doctor.id} className="doctor-card">
                <div className="card-header">
                  <div className="doctor-avatar">
                    {getInitials(doctor.name)}
                  </div>
                  <h2 className="doctor-name">{doctor.name}</h2>
                  <p className="doctor-specialty">{getSpecialtyName(doctor)}</p>
                </div>

                <div className="card-body">
                  <div className="info-row">
                    <span className="info-label">Availability:</span>
                    <span className={`availability ${doctor.is_active ? 'available' : 'unavailable'}`}>
                      {doctor.is_active ? 'Available' : 'Not Available'}
                    </span>
                  </div>

                  <div className="info-row">
                    <span className="info-label">Available Days:</span>
                    <span className="info-value">Mon, Wed, Fri</span>
                  </div>

                  <div className="info-row">
                    <span className="info-label">Hours:</span>
                    <span className="info-value">9:00 AM - 5:00 PM</span>
                  </div>

                  <div className="info-row">
                    <span className="info-label">Experience:</span>
                    <span className="info-value">
                      {doctor.created_at ? 
                        `Since ${new Date(doctor.created_at).getFullYear()}` : 
                        'Experienced'}
                    </span>
                  </div>
                </div>

                <div className="card-footer">
                  <button className="action-btn" onClick={() => navigate('/appointments')}>
                    View Profile
                  </button>
                  <button
                    className="action-btn primary"
                    onClick={() => navigate('/appointments')}
                    disabled={!doctor.is_active}
                  >
                    Book Appointment
                  </button>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* Footer */}
      <div className="page-footer">
        <p>Need help finding a specialist? Contact our support team.</p>
        <button onClick={fetchDoctors} className="action-btn">
          Refresh List
        </button>
      </div>
    </div>
  );
};

export default DoctorsPage;
