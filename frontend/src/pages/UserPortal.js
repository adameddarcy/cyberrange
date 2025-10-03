import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import axios from 'axios';

function UserPortal() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadStatus, setUploadStatus] = useState('');
  const [loading, setLoading] = useState(false);

  const handleFileChange = (e) => {
    setSelectedFile(e.target.files[0]);
  };

  const handleFileUpload = async (e) => {
    e.preventDefault();
    if (!selectedFile) {
      setUploadStatus('Please select a file to upload');
      return;
    }

    setLoading(true);
    setUploadStatus('');

    try {
      const formData = new FormData();
      formData.append('file', selectedFile);

      const response = await axios.post('/api/upload', formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      if (response.data.success) {
        setUploadStatus('File uploaded successfully!');
        setSelectedFile(null);
        // Reset file input
        e.target.reset();
      } else {
        setUploadStatus('Upload failed: ' + response.data.message);
      }
    } catch (error) {
      setUploadStatus('Upload failed: ' + (error.response?.data?.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  const handleSSRFTest = async () => {
    try {
      // VULNERABILITY: This will trigger SSRF vulnerability
      const response = await axios.get('/api/fetch-url?url=http://localhost:3000/.env');
      setUploadStatus('SSRF Test Result: ' + JSON.stringify(response.data));
    } catch (error) {
      setUploadStatus('SSRF Test Error: ' + error.message);
    }
  };

  return (
    <div>
      <header className="header">
        <h1>W Corp Portal</h1>
        <p>Welcome, {user?.username}!</p>
      </header>

      <nav className="nav">
        <Link to="/">Home</Link>
        <Link to={`/portal/profile/${user?.id}`}>My Profile</Link>
        <button className="btn btn-danger" onClick={logout}>Logout</button>
      </nav>

      <div className="container">
        <div className="card">
          <h2>User Dashboard</h2>
          <p>Welcome to your personal portal. Here you can manage your account and upload files.</p>
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1rem', marginTop: '2rem' }}>
            <div className="profile-card">
              <h3>Account Information</h3>
              <div className="profile-info">
                <div>
                  <strong>Username:</strong> {user?.username}
                </div>
                <div>
                  <strong>Email:</strong> {user?.email}
                </div>
                <div>
                  <strong>Role:</strong> {user?.role}
                </div>
                <div>
                  <strong>User ID:</strong> {user?.id}
                </div>
              </div>
              <Link to={`/portal/profile/${user?.id}`} className="btn">
                View Full Profile
              </Link>
            </div>

            <div className="profile-card">
              <h3>Quick Actions</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                <Link to={`/portal/profile/${user?.id}`} className="btn btn-secondary">
                  Edit Profile
                </Link>
                <button onClick={handleSSRFTest} className="btn btn-secondary">
                  Test SSRF (Demo)
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="card">
          <h2>File Upload</h2>
          <p>Upload files to your personal storage. All file types are accepted.</p>
          
          <form onSubmit={handleFileUpload}>
            <div className="form-group">
              <label htmlFor="file">Select File:</label>
              <input
                type="file"
                id="file"
                onChange={handleFileChange}
                required
              />
            </div>

            <button 
              type="submit" 
              className="btn btn-success" 
              disabled={loading || !selectedFile}
            >
              {loading ? <span className="loading"></span> : 'Upload File'}
            </button>
          </form>

          {uploadStatus && (
            <div className={`alert ${uploadStatus.includes('successfully') ? 'alert-success' : 'alert-error'}`} style={{ marginTop: '1rem' }}>
              {uploadStatus}
            </div>
          )}
        </div>

        <div className="card">
          <h2>Security Testing</h2>
          <p>This portal contains intentional vulnerabilities for educational purposes:</p>
          <ul style={{ textAlign: 'left', marginTop: '1rem' }}>
            <li><strong>IDOR:</strong> Try accessing other user profiles by changing the ID in the URL</li>
            <li><strong>SSRF:</strong> Use the "Test SSRF" button to see server-side request forgery</li>
            <li><strong>File Upload:</strong> Upload any file type to test upload vulnerabilities</li>
            <li><strong>Session Management:</strong> Check browser storage for predictable session tokens</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default UserPortal;
