import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import LandingPage from './pages/LandingPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import UserPortal from './pages/UserPortal';
import AdminPortal from './pages/AdminPortal';
import UserProfile from './pages/UserProfile';
import './App.css';

// Protected Route Component
function ProtectedRoute({ children, adminOnly = false }) {
  const { user, isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (adminOnly && user?.role !== 'admin') {
    return <Navigate to="/portal" replace />;
  }
  
  return children;
}

function App() {
  return (
    <AuthProvider>
      <Router basename="/wcorp">
        <div className="App">
          <Routes>
            <Route path="/" element={<LandingPage />} />
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route 
              path="/portal" 
              element={
                <ProtectedRoute>
                  <UserPortal />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/admin" 
              element={
                <ProtectedRoute adminOnly={true}>
                  <AdminPortal />
                </ProtectedRoute>
              } 
            />
            <Route 
              path="/portal/profile/:id" 
              element={
                <ProtectedRoute>
                  <UserProfile />
                </ProtectedRoute>
              } 
            />
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
