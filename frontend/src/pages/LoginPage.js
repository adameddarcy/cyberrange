import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

function LoginPage() {
  const [formData, setFormData] = useState({
    username: '',
    password: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const result = await login(formData.username, formData.password);
      
      if (result.success) {
        // Redirect based on user role
        if (result.user?.role === 'admin') {
          navigate('/admin');
        } else {
          navigate('/portal');
        }
      } else {
        setError(result.message);
      }
    } catch (error) {
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <header className="header">
        <h1>W Corp</h1>
        <p>Login to Your Account</p>
      </header>

      <nav className="nav">
        <Link to="/">Home</Link>
        <Link to="/register">Register</Link>
      </nav>

      <div className="container">
        <div className="card">
          <h2>Login</h2>
          
          {error && (
            <div className="alert alert-error">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="username">Username:</label>
              <input
                type="text"
                id="username"
                name="username"
                value={formData.username}
                onChange={handleChange}
                required
                placeholder="Enter your username"
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password:</label>
              <input
                type="password"
                id="password"
                name="password"
                value={formData.password}
                onChange={handleChange}
                required
                placeholder="Enter your password"
              />
            </div>

            <button 
              type="submit" 
              className="btn btn-success" 
              disabled={loading}
              style={{ width: '100%' }}
            >
              {loading ? <span className="loading"></span> : 'Login'}
            </button>
          </form>

          <div style={{ marginTop: '1rem', textAlign: 'center' }}>
            <p>Don't have an account? <Link to="/register">Register here</Link></p>
          </div>
        </div>

        <div className="card">
          <h3>Demo Accounts</h3>
          <p>Use these accounts to test different user roles:</p>
          <div style={{ textAlign: 'left', marginTop: '1rem' }}>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>Admin:</strong> admin / admin123
            </div>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>User:</strong> john.doe / password123
            </div>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>User:</strong> jane.smith / qwerty
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
