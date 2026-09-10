import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldAlert, Lock, ArrowRight, Loader2 } from 'lucide-react';
import { API_BASE_URL } from '../../config';

export default function AdminLogin() {
  const [adminKey, setAdminKey] = useState('');
  const [error, setError] = useState('');
  const [isVerifying, setIsVerifying] = useState(false);
  const navigate = useNavigate();

  // If already logged in, redirect instantly
  useEffect(() => {
    const existingKey = localStorage.getItem('civic_admin_key');
    if (existingKey) {
      navigate('/admin/dashboard');
    }
  }, [navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    
    const key = adminKey.trim();
    if (!key) {
      setError('Please enter the administrative key.');
      return;
    }

    setIsVerifying(true);

    try {
      // Make a real request to the backend to verify the key
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/verify`, {
        method: 'GET',
        headers: {
          'x-admin-key': key,
        },
      });

      if (response.ok) {
        // Server accepted the key! Save it and enter.
        localStorage.setItem('civic_admin_key', key);
        navigate('/admin/dashboard');
      } else {
        // Server rejected it (401 or 403)
        setError('Invalid administrative key. Access denied.');
      }
    } catch (err) {
      setError('Failed to connect to the city servers.');
    } finally {
      setIsVerifying(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#050505] flex items-center justify-center px-4 relative overflow-hidden">
      
      {/* Background Glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[400px] bg-[#6B4EFF]/20 blur-[120px] rounded-full pointer-events-none -z-10"></div>

      <div className="w-full max-w-md bg-[#0A0A0A]/80 backdrop-blur-xl border border-white/10 rounded-3xl p-8 shadow-2xl">
        <div className="flex justify-center mb-6">
          <div className="bg-[#6B4EFF]/20 p-4 rounded-full border border-[#6B4EFF]/30">
            <ShieldAlert size={40} className="text-[#6B4EFF]" />
          </div>
        </div>
        
        <h2 className="text-3xl font-bold text-center text-white mb-2">Restricted Access</h2>
        <p className="text-center text-gray-400 mb-8">City Officials & Authorized Personnel Only</p>

        {error && (
          <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 rounded-xl text-red-400 text-sm text-center font-medium">
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-400 mb-2">Administrative Master Key</label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <Lock size={18} className="text-gray-500" />
              </div>
              <input
                type="password"
                value={adminKey}
                onChange={(e) => setAdminKey(e.target.value)}
                disabled={isVerifying}
                className="w-full pl-12 pr-4 py-3 bg-[#111] border border-white/10 rounded-xl text-white placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-[#6B4EFF] focus:border-transparent transition-all disabled:opacity-50"
                placeholder="Enter x-admin-key..."
                autoComplete="off"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isVerifying}
            className="w-full bg-[#6B4EFF] hover:bg-[#5A3EE0] disabled:bg-[#6B4EFF]/50 text-white font-bold py-3 px-4 rounded-xl transition-all flex items-center justify-center gap-2 group"
          >
            {isVerifying ? (
              <>
                <Loader2 size={18} className="animate-spin" />
                Verifying...
              </>
            ) : (
              <>
                Authenticate Session
                <ArrowRight size={18} className="group-hover:translate-x-1 transition-transform" />
              </>
            )}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-white/10 text-center">
          <a href="/" className="text-sm text-gray-500 hover:text-white transition-colors">
            &larr; Return to Public Dashboard
          </a>
        </div>
      </div>
    </div>
  );
}