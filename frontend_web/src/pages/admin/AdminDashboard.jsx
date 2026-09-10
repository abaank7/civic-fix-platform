import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { LogOut, MapPin, AlertTriangle, Trash2, CheckCircle, Clock, Image as ImageIcon, ExternalLink, Filter } from 'lucide-react';
import { API_BASE_URL } from '../../config';

// --- CUSTOM INSTANT DROPDOWN ---
const CustomDropdown = ({ value, onChange, options }) => {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        onBlur={() => setTimeout(() => setIsOpen(false), 150)} 
        className="w-full bg-[#111] border border-white/10 text-white text-[11px] rounded-md px-3 py-2 flex justify-between items-center hover:bg-white/5 transition-colors focus:border-[#6B4EFF] outline-none"
      >
        {options.find(o => o.value === value)?.label || value}
        <span className="opacity-40 text-[9px] ml-2">▼</span>
      </button>
      
      {isOpen && (
        <div className="absolute z-50 w-full mt-1 bg-[#1A1A1C] border border-white/10 rounded-md shadow-xl overflow-hidden py-1">
          {options.map((opt) => (
            <div
              key={opt.value}
              onClick={() => { onChange(opt.value); setIsOpen(false); }}
              className={`px-3 py-1.5 text-[11px] cursor-pointer transition-colors ${
                value === opt.value ? 'bg-[#6B4EFF]/20 text-[#6B4EFF] font-bold' : 'text-gray-300 hover:bg-white/10 hover:text-white'
              }`}
            >
              {opt.label}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default function AdminDashboard() {
  const [issues, setIssues] = useState([]);
  const [selectedIssue, setSelectedIssue] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // --- FILTER STATES ---
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterCategory, setFilterCategory] = useState('All');
  const [filterDate, setFilterDate] = useState('All Time');
  const [sortBy, setSortBy] = useState('Newest');
  
  const navigate = useNavigate();
  const adminKey = localStorage.getItem('civic_admin_key');

  // Security Check
  useEffect(() => {
    if (!adminKey) {
      navigate('/admin');
    } else {
      fetchIssues();
    }
  }, [adminKey, navigate]);

  const fetchIssues = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/issues/`);
      const data = await response.json();
      setIssues(data);
    } catch (err) {
      console.error("Failed to fetch:", err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleUpdateStatus = async (issueId, newStatus) => {
    setIsUpdating(true);
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/issues/${issueId}/status`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': adminKey,
        },
        body: JSON.stringify({ status: newStatus }),
      });

      if (response.ok) {
        setIssues(issues.map(i => i.id === issueId ? { ...i, status: newStatus } : i));
        setSelectedIssue({ ...selectedIssue, status: newStatus });
      } else {
        alert("Server rejected the update. Check your Admin Key.");
      }
    } catch (err) {
      alert("Network error.");
    } finally {
      setIsUpdating(false);
    }
  };

  const handleDeleteIssue = async (issueId) => {
    const confirmed = window.confirm("Are you sure you want to permanently delete this report? This action cannot be undone.");
    if (!confirmed) return;

    setIsDeleting(true);
    try {
      const response = await fetch(`${API_BASE_URL}/api/v1/admin/issues/${issueId}`, {
        method: 'DELETE',
        headers: {
          'x-admin-key': adminKey,
        },
      });

      if (response.ok) {
        setIssues(issues.filter(i => i.id !== issueId));
        setSelectedIssue(null);
      } else {
        alert("Failed to delete. Check your Admin Key.");
      }
    } catch (err) {
      alert("Network error.");
    } finally {
      setIsDeleting(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('civic_admin_key');
    navigate('/admin');
  };

  // --- UI Helpers ---
  const getStatusColor = (status) => {
    switch (status) {
      case 'Resolved': return 'text-emerald-400 border-emerald-400/30 bg-emerald-400/10';
      case 'In Progress': return 'text-amber-400 border-amber-400/30 bg-amber-400/10';
      default: return 'text-blue-400 border-blue-400/30 bg-blue-400/10';
    }
  };

  // --- FILTERING & SORTING LOGIC ---
  const processedIssues = issues
    .filter(issue => filterStatus === 'All' || (issue.status || 'Pending') === filterStatus)
    .filter(issue => filterCategory === 'All' || (issue.category || 'Unknown') === filterCategory)
    .filter(issue => {
      if (filterDate === 'All Time') return true;
      const issueDate = new Date(issue.created_at);
      const today = new Date();
      if (filterDate === 'Today') return issueDate.toDateString() === today.toDateString();
      if (filterDate === 'Past 7 Days') return issueDate >= new Date(today.getTime() - (7 * 24 * 60 * 60 * 1000));
      if (filterDate === 'Past 30 Days') return issueDate >= new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
      return true;
    })
    .sort((a, b) => {
      const dateA = new Date(a.created_at);
      const dateB = new Date(b.created_at);
      return sortBy === 'Newest' ? dateB - dateA : dateA - dateB;
    });

  return (
    <div className="flex h-screen bg-[#050505] text-gray-200 font-sans overflow-hidden text-sm">
      
      {/* LEFT PANE: List of Issues */}
      <div className="w-[320px] border-r border-white/10 flex flex-col bg-[#0A0A0A] flex-shrink-0">
        
        {/* Header */}
        <div className="p-4 border-b border-white/10 flex justify-between items-center bg-[#050505]">
          <div>
            <h1 className="text-base font-bold tracking-tight text-white">Command Center</h1>
            <p className="text-[10px] text-[#6B4EFF] font-medium uppercase tracking-wider mt-0.5">Admin Session</p>
          </div>
          <button onClick={handleLogout} className="p-1.5 hover:bg-white/10 rounded-md transition-colors text-gray-500 hover:text-red-400" title="Lock Session">
            <LogOut size={16} />
          </button>
        </div>

        {/* --- COMPACT FILTER PANEL --- */}
        <div className="p-3 border-b border-white/10 bg-[#0A0A0A]">
          <div className="flex items-center gap-1.5 text-gray-500 mb-2.5">
            <Filter size={12} />
            <span className="text-[10px] font-bold uppercase tracking-wider">Filters & Sort</span>
          </div>
          <div className="grid grid-cols-2 gap-2 mb-2">
            <CustomDropdown 
              value={filterStatus} onChange={setFilterStatus} 
              options={[{ value: 'All', label: 'All Statuses' }, { value: 'Pending', label: 'Pending' }, { value: 'In Progress', label: 'In Progress' }, { value: 'Resolved', label: 'Resolved' }]} 
            />
            <CustomDropdown 
              value={filterCategory} onChange={setFilterCategory} 
              options={[{ value: 'All', label: 'All Depts' }, { value: 'PWD', label: 'PWD' }, { value: 'JSD', label: 'JSD' }, { value: 'SMC', label: 'SMC' }, { value: 'KPDCL', label: 'KPDCL' }, { value: 'JKFD', label: 'JKFD' }]} 
            />
            <CustomDropdown 
              value={filterDate} onChange={setFilterDate} 
              options={[{ value: 'All Time', label: 'All Time' }, { value: 'Today', label: 'Today' }, { value: 'Past 7 Days', label: 'Past 7 Days' }, { value: 'Past 30 Days', label: 'Past 30 Days' }]} 
            />
            <CustomDropdown 
              value={sortBy} onChange={setSortBy} 
              options={[{ value: 'Newest', label: 'Newest First' }, { value: 'Oldest', label: 'Oldest First' }]} 
            />
          </div>
          <div className="text-right text-[10px] text-gray-500">
            Showing {processedIssues.length} of {issues.length}
          </div>
        </div>

        {/* List */}
        <div className="flex-1 overflow-y-auto p-3 space-y-2 custom-scrollbar">
          {isLoading ? (
            <div className="text-center py-6 text-xs text-[#6B4EFF] animate-pulse">Loading data...</div>
          ) : processedIssues.length === 0 ? (
            <div className="text-center py-6 text-xs text-gray-500 border border-white/5 rounded-lg">No reports match.</div>
          ) : (
            processedIssues.map((issue) => {
              const isSelected = selectedIssue?.id === issue.id;
              return (
                <div 
                  key={issue.id}
                  onClick={() => setSelectedIssue(issue)}
                  className={`p-3 rounded-lg border cursor-pointer transition-all duration-200 ${
                    isSelected ? 'bg-[#6B4EFF]/10 border-[#6B4EFF]' : 'bg-[#111] border-white/5 hover:border-white/10'
                  }`}
                >
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-[10px] font-bold text-gray-400">
                      {issue.category || 'UNKNOWN'}
                    </span>
                    <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded border ${getStatusColor(issue.status)}`}>
                      {(issue.status || 'PENDING').toUpperCase()}
                    </span>
                  </div>
                  <p className="text-xs text-gray-300 line-clamp-2 leading-relaxed">
                    {issue.description || "No citizen description."}
                  </p>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* RIGHT PANE: Inspector */}
      <div className="flex-1 bg-[#050505] flex flex-col overflow-y-auto relative">
        {!selectedIssue ? (
          <div className="flex-1 flex flex-col items-center justify-center text-gray-600">
            <AlertTriangle size={32} className="mb-3 opacity-30" />
            <p className="text-sm">Select a report to inspect</p>
          </div>
        ) : (
          <div className="max-w-3xl w-full mx-auto p-6">
            
            {/* Inspector Header: Status Control */}
            <div className="flex justify-between items-center mb-5 pb-5 border-b border-white/10">
              <h2 className="text-lg font-bold text-white">Report Details</h2>
              
              <div className="flex items-center gap-3">
                <span className="text-xs text-gray-500 uppercase tracking-wider font-bold">Update Status:</span>
                {isUpdating ? (
                  <div className="h-8 w-28 flex items-center justify-center bg-white/5 rounded border border-white/10 animate-pulse text-xs">Saving...</div>
                ) : (
                  <select
                    value={selectedIssue.status || 'Pending'}
                    onChange={(e) => handleUpdateStatus(selectedIssue.id, e.target.value)}
                    className={`bg-[#111] border text-xs rounded px-3 py-1.5 outline-none cursor-pointer font-bold ${getStatusColor(selectedIssue.status)}`}
                  >
                    <option value="Pending">Pending</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Resolved">Resolved</option>
                  </select>
                )}
              </div>
            </div>

            {/* Evidence & Details Row */}
            <div className="flex flex-col lg:flex-row gap-6 mb-6">
              
              {/* Image Evidence (CONSTRAINED) */}
              <div className="flex-1">
                <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-2">Evidence Photo</h3>
                <div className="w-full h-64 bg-[#0A0A0A] rounded-lg border border-white/10 overflow-hidden flex items-center justify-center">
                  {selectedIssue.image_url ? (
                    <img src={selectedIssue.image_url} alt="Evidence" className="w-full h-full object-contain" />
                  ) : (
                    <div className="flex flex-col items-center text-gray-700"><ImageIcon size={32} className="mb-2" /><span className="text-xs">No image</span></div>
                  )}
                </div>
              </div>

              {/* Data Blocks */}
              <div className="lg:w-64 flex flex-col gap-4">
                <div className="bg-[#0A0A0A] p-4 rounded-lg border border-white/10">
                  <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Department</h3>
                  <p className="text-sm font-semibold text-white">{selectedIssue.category || 'N/A'}</p>
                </div>
                <div className="bg-[#0A0A0A] p-4 rounded-lg border border-white/10">
                  <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Coordinates</h3>
                  {selectedIssue.latitude ? (
                    <a href={`https://www.google.com/maps/search/?api=1&query=${selectedIssue.latitude},${selectedIssue.longitude}`} target="_blank" rel="noreferrer" className="flex items-center text-xs text-[#6B4EFF] hover:underline font-mono">
                      <MapPin size={12} className="mr-1.5" />
                      {selectedIssue.latitude.toFixed(4)}, {selectedIssue.longitude.toFixed(4)}
                      <ExternalLink size={10} className="ml-1" />
                    </a>
                  ) : (
                    <p className="text-xs text-gray-500">Location hidden</p>
                  )}
                </div>
                <div className="bg-[#0A0A0A] p-4 rounded-lg border border-white/10 flex-1">
                   <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-1">Reported</h3>
                   <div className="flex items-center text-xs text-gray-300">
                      <Clock size={12} className="mr-1.5 text-gray-500" />
                      {new Date(selectedIssue.created_at).toLocaleDateString()}
                   </div>
                </div>
              </div>
            </div>

            {/* Description */}
            <div className="mb-8">
              <h3 className="text-[10px] font-bold text-gray-500 uppercase tracking-wider mb-2">Citizen Notes</h3>
              <div className="bg-[#0A0A0A] p-4 rounded-lg border border-white/10 text-xs text-gray-300 leading-relaxed min-h-[80px]">
                {selectedIssue.description || "The citizen submitted this report without a description."}
              </div>
            </div>

            {/* Danger Zone */}
            <div className="pt-6 border-t border-red-500/10 flex items-center justify-between">
              <div>
                <h3 className="text-xs font-bold text-red-500 uppercase tracking-wider mb-1">Danger Zone</h3>
                <p className="text-[10px] text-gray-500">Permanently remove invalid or test reports.</p>
              </div>
              <button 
                onClick={() => handleDeleteIssue(selectedIssue.id)}
                disabled={isDeleting}
                className="px-4 py-2 bg-red-500/10 hover:bg-red-500/20 border border-red-500/20 text-red-400 text-xs font-bold rounded-md transition-colors flex items-center gap-1.5"
              >
                {isDeleting ? 'Deleting...' : <><Trash2 size={14} /> Delete Report</>}
              </button>
            </div>

          </div>
        )}
      </div>

    </div>
  );
}