import React, { useState, useEffect } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

function UserProfile() {
  const { id } = useParams();
  const { user: currentUser, logout } = useAuth();
  const navigate = useNavigate();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [sensitiveData, setSensitiveData] = useState(null);
  const [internalNotes, setInternalNotes] = useState([]);

  useEffect(() => {
    fetchUserProfile();
  }, [id]);

  const fetchUserProfile = async () => {
    try {
      // VULNERABILITY: IDOR - No authorization check, any user can access any profile
      const response = await axios.get(`/api/user/profile/${id}`);
      
      if (response.data.success) {
        setProfile(response.data.user);
        
        // Try to fetch sensitive data (should be protected)
        try {
          const sensitiveResponse = await axios.get(`/api/user/sensitive/${id}`);
          if (sensitiveResponse.data.success) {
            setSensitiveData(sensitiveResponse.data.data);
          }
        } catch (error) {
          // Sensitive data might be protected
          console.log('Sensitive data not accessible');
        }

        // Try to fetch internal notes (should be protected)
        try {
          const notesResponse = await axios.get(`/api/user/notes/${id}`);
          if (notesResponse.data.success) {
            setInternalNotes(notesResponse.data.notes);
          }
        } catch (error) {
          // Internal notes might be protected
          console.log('Internal notes not accessible');
        }
      } else {
        setError(response.data.message);
      }
    } catch (error) {
      setError('Failed to load user profile: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div>
        <header className="header">
          <h1>W Corp</h1>
        </header>
        <div className="container">
          <div className="card">
            <div style={{ textAlign: 'center' }}>
              <span className="loading"></span>
              <p>Loading profile...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div>
        <header className="header">
          <h1>W Corp</h1>
        </header>
        <nav className="nav">
          <Link to="/portal">Portal</Link>
          <button className="btn btn-danger" onClick={logout}>Logout</button>
        </nav>
        <div className="container">
          <div className="card">
            <div className="alert alert-error">
              {error}
            </div>
            <Link to="/portal" className="btn">Back to Portal</Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <header className="header">
        <h1>W Corp</h1>
        <p>User Profile</p>
      </header>

      <nav className="nav">
        <Link to="/">Home</Link>
        <Link to="/portal">Portal</Link>
        {currentUser?.role === 'admin' && <Link to="/admin">Admin</Link>}
        <button className="btn btn-danger" onClick={logout}>Logout</button>
      </nav>

      <div className="container">
        <div className="card">
          <h2>User Profile: {profile?.username}</h2>
          
          <div className="profile-info">
            <div>
              <strong>User ID:</strong> {profile?.id}
            </div>
            <div>
              <strong>Username:</strong> {profile?.username}
            </div>
            <div>
              <strong>Email:</strong> {profile?.email}
            </div>
            <div>
              <strong>Role:</strong> {profile?.role}
            </div>
            <div>
              <strong>Created:</strong> {new Date(profile?.created_at).toLocaleDateString()}
            </div>
            <div>
              <strong>Last Updated:</strong> {new Date(profile?.updated_at).toLocaleDateString()}
            </div>
          </div>

          <div style={{ marginTop: '2rem' }}>
            <Link to="/portal" className="btn btn-secondary">
              Back to Portal
            </Link>
            {currentUser?.id === profile?.id && (
              <button className="btn" style={{ marginLeft: '1rem' }}>
                Edit Profile
              </button>
            )}
          </div>
        </div>

        {sensitiveData && (
          <div className="card">
            <h3>⚠️ Sensitive Data (IDOR Vulnerability)</h3>
            <div className="alert alert-warning">
              <strong>Warning:</strong> This data should be protected from unauthorized access!
            </div>
            <div className="profile-info">
              {sensitiveData.map((item, index) => (
                <div key={index}>
                  <strong>{item.data_type.toUpperCase()}:</strong> {item.data_value}
                </div>
              ))}
            </div>
          </div>
        )}

        {internalNotes.length > 0 && (
          <div className="card">
            <h3>🔒 Internal Notes (IDOR Vulnerability)</h3>
            <div className="alert alert-warning">
              <strong>Warning:</strong> These internal notes should be protected from unauthorized access!
            </div>
            {internalNotes.map((note, index) => (
              <div key={index} style={{ 
                marginBottom: '1rem', 
                padding: '1rem', 
                backgroundColor: note.is_confidential ? '#fff3cd' : '#f8f9fa',
                border: '1px solid #ddd',
                borderRadius: '4px'
              }}>
                <div style={{ fontWeight: 'bold', marginBottom: '0.5rem' }}>
                  {note.is_confidential ? '🔒 Confidential' : '📝 Note'}
                </div>
                <div>{note.note}</div>
                <div style={{ fontSize: '0.8rem', color: '#666', marginTop: '0.5rem' }}>
                  {new Date(note.created_at).toLocaleString()}
                </div>
              </div>
            ))}
          </div>
        )}

        <div className="card">
          <h3>IDOR Vulnerability Demonstration</h3>
          <p>This page demonstrates <strong>A01: Broken Access Control (IDOR)</strong>:</p>
          <ul style={{ textAlign: 'left', marginTop: '1rem' }}>
            <li>Any authenticated user can access any user's profile by changing the ID in the URL</li>
            <li>Sensitive data like SSN and credit card numbers are exposed</li>
            <li>Internal notes containing confidential information are accessible</li>
            <li>No authorization checks are performed to verify if the user should have access</li>
          </ul>
          
          <div style={{ marginTop: '1rem' }}>
            <p><strong>Try this:</strong> Change the user ID in the URL to access other users' profiles:</p>
            <div style={{ backgroundColor: '#f8f9fa', padding: '1rem', borderRadius: '4px', fontFamily: 'monospace' }}>
              /portal/profile/1 (admin profile)<br/>
              /portal/profile/2 (john.doe profile)<br/>
              /portal/profile/3 (jane.smith profile)
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default UserProfile;
