import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import PublicDashboard from './pages/public/PublicDashboard';
import AdminLogin from './pages/admin/AdminLogin';
import AdminDashboard from './pages/admin/AdminDashboard';

function App() {
  return (
    <Router>
      <div className="min-h-screen bg-[#050505] text-white selection:bg-[#6B4EFF] selection:text-white">
        <Routes>
          {/* Public Citizen Route */}
          <Route path="/" element={<PublicDashboard />} />

          {/* Secure Admin Routes */}
          <Route path="/admin" element={<AdminLogin />} />
          <Route path="/admin/dashboard" element={<AdminDashboard />} />

          {/* Fallback for invalid URLs */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;