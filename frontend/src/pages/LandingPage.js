import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

function LandingPage() {
  const { isAuthenticated, user, logout } = useAuth();

  return (
    <div>
      <header className="header">
        <h1>W Corp</h1>
        <p>Leading Technology Solutions</p>
      </header>

      <nav className="nav">
        {isAuthenticated ? (
          <>
            <span>Welcome, {user?.username}!</span>
            <Link to="/portal">Portal</Link>
            {user?.role === 'admin' && <Link to="/admin">Admin</Link>}
            <button className="btn btn-danger" onClick={logout}>Logout</button>
          </>
        ) : (
          <>
            <Link to="/login">Login</Link>
            <Link to="/register">Register</Link>
          </>
        )}
      </nav>

      <div className="container">
        <div className="card">
          <h2>Welcome to W Corp</h2>
          <p>
            W Corp is a leading technology company providing innovative solutions 
            for businesses worldwide. Our platform offers secure access to your 
            personal portal where you can manage your account, upload files, and 
            access exclusive content.
          </p>
          
          {!isAuthenticated && (
            <div>
              <p>Get started by creating an account or logging in to your existing account.</p>
              <div style={{ marginTop: '2rem' }}>
                <Link to="/register" className="btn btn-success" style={{ marginRight: '1rem' }}>
                  Create Account
                </Link>
                <Link to="/login" className="btn">
                  Login
                </Link>
              </div>
            </div>
          )}

          {isAuthenticated && (
            <div>
              <p>You're already logged in! Access your portal to get started.</p>
              <div style={{ marginTop: '2rem' }}>
                <Link to="/portal" className="btn btn-success">
                  Go to Portal
                </Link>
              </div>
            </div>
          )}
        </div>

        <div className="card">
          <h3>Our Services</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1rem', marginTop: '1rem' }}>
            <div>
              <h4>Secure File Management</h4>
              <p>Upload and manage your files securely in our cloud-based platform.</p>
            </div>
            <div>
              <h4>User Profiles</h4>
              <p>Maintain detailed profiles with personal information and preferences.</p>
            </div>
            <div>
              <h4>Admin Dashboard</h4>
              <p>Administrators have access to advanced management tools and analytics.</p>
            </div>
          </div>
        </div>

        <div className="card">
          <h3>Security Notice</h3>
          <div className="alert alert-warning">
            <strong>Important:</strong> This is a cyber range environment designed for educational purposes. 
            Do not use real personal information or passwords. This system contains intentional vulnerabilities 
            for security training and should not be used in production environments.
          </div>
        </div>
      </div>
    </div>
  );
}

export default LandingPage;
