import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

function AdminPortal() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalFiles: 0,
    totalSessions: 0
  });
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchAdminData();
  }, []);

  const fetchAdminData = async () => {
    try {
      // VULNERABILITY: No authorization check - any authenticated user can access this
      const [usersResponse, statsResponse] = await Promise.all([
        axios.get('/api/admin/users'),
        axios.get('/api/admin/stats')
      ]);

      setUsers(usersResponse.data.users || []);
      setStats(statsResponse.data.stats || {});
    } catch (error) {
      setError('Failed to load admin data: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleUserAction = async (userId, action) => {
    try {
      const response = await axios.post(`/api/admin/users/${userId}/${action}`);
      if (response.data.success) {
        fetchAdminData(); // Refresh data
        setError('');
      } else {
        setError(response.data.message);
      }
    } catch (error) {
      setError('Action failed: ' + error.message);
    }
  };

  if (loading) {
    return (
      <div>
        <header className="header">
          <h1>W Corp Admin Portal</h1>
        </header>
        <div className="container">
          <div className="card">
            <div style={{ textAlign: 'center' }}>
              <span className="loading"></span>
              <p>Loading admin data...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div>
      <header className="header">
        <h1>W Corp Admin Portal</h1>
        <p>Administrator Dashboard</p>
      </header>

      <nav className="nav">
        <Link to="/">Home</Link>
        <Link to="/portal">User Portal</Link>
        <button className="btn btn-danger" onClick={logout}>Logout</button>
      </nav>

      <div className="container">
        {error && (
          <div className="alert alert-error">
            {error}
          </div>
        )}

        <div className="card">
          <h2>Admin Dashboard</h2>
          <p>Welcome, {user?.username}. You have administrative privileges.</p>
          
          <div className="admin-stats">
            <div className="stat-card">
              <div className="stat-number">{stats.totalUsers}</div>
              <div className="stat-label">Total Users</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">{stats.totalFiles}</div>
              <div className="stat-label">Total Files</div>
            </div>
            <div className="stat-card">
              <div className="stat-number">{stats.totalSessions}</div>
              <div className="stat-label">Active Sessions</div>
            </div>
          </div>
        </div>

        <div className="card">
          <h2>User Management</h2>
          <p>Manage user accounts and permissions.</p>
          
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '1rem' }}>
              <thead>
                <tr style={{ backgroundColor: '#f8f9fa' }}>
                  <th style={{ padding: '0.75rem', border: '1px solid #ddd', textAlign: 'left' }}>ID</th>
                  <th style={{ padding: '0.75rem', border: '1px solid #ddd', textAlign: 'left' }}>Username</th>
                  <th style={{ padding: '0.75rem', border: '1px solid #ddd', textAlign: 'left' }}>Email</th>
                  <th style={{ padding: '0.75rem', border: '1px solid #ddd', textAlign: 'left' }}>Role</th>
                  <th style={{ padding: '0.75rem', border: '1px solid #ddd', textAlign: 'left' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id}>
                    <td style={{ padding: '0.75rem', border: '1px solid #ddd' }}>{user.id}</td>
                    <td style={{ padding: '0.75rem', border: '1px solid #ddd' }}>{user.username}</td>
                    <td style={{ padding: '0.75rem', border: '1px solid #ddd' }}>{user.email}</td>
                    <td style={{ padding: '0.75rem', border: '1px solid #ddd' }}>
                      <span style={{ 
                        padding: '0.25rem 0.5rem', 
                        borderRadius: '4px', 
                        backgroundColor: user.role === 'admin' ? '#e74c3c' : '#3498db',
                        color: 'white',
                        fontSize: '0.8rem'
                      }}>
                        {user.role}
                      </span>
                    </td>
                    <td style={{ padding: '0.75rem', border: '1px solid #ddd' }}>
                      <Link to={`/portal/profile/${user.id}`} className="btn btn-secondary" style={{ marginRight: '0.5rem', fontSize: '0.8rem' }}>
                        View
                      </Link>
                      <button 
                        className="btn btn-danger" 
                        style={{ fontSize: '0.8rem' }}
                        onClick={() => handleUserAction(user.id, 'delete')}
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <h2>System Information</h2>
          <div style={{ textAlign: 'left' }}>
            <p><strong>Server:</strong> Node.js Express</p>
            <p><strong>Database:</strong> MySQL 8.0</p>
            <p><strong>PHP Service:</strong> Available on port 8080</p>
            <p><strong>Upload Directory:</strong> /uploads</p>
            <p><strong>Environment:</strong> Development</p>
          </div>
        </div>

        <div className="card">
          <h2>Security Vulnerabilities</h2>
          <p>This admin portal demonstrates several OWASP Top 10 vulnerabilities:</p>
          <ul style={{ textAlign: 'left', marginTop: '1rem' }}>
            <li><strong>A01 - Broken Access Control:</strong> No proper authorization checks</li>
            <li><strong>A02 - Cryptographic Failures:</strong> Passwords stored in plain text</li>
            <li><strong>A05 - Security Misconfiguration:</strong> Exposed system information</li>
            <li><strong>A07 - Identification and Authentication Failures:</strong> Predictable session tokens</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default AdminPortal;
