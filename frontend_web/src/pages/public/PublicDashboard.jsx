import { useState, useEffect } from 'react';
import { MapPin, Clock, CheckCircle, AlertCircle, ShieldCheck, Image as ImageIcon, ExternalLink, Filter } from 'lucide-react';
import { API_BASE_URL } from '../../config';


export default function PublicDashboard() {
  const [issues, setIssues] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  // --- FILTER STATES ---
  const [filterStatus, setFilterStatus] = useState('All');
  const [filterCategory, setFilterCategory] = useState('All');
  const [filterDate, setFilterDate] = useState('All Time');
  const [sortBy, setSortBy] = useState('Newest');

  useEffect(() => {
    fetchIssues();
  }, []);

  const fetchIssues = async () => {
    try {
    //   const response = await fetch('http://127.0.0.1:8001/api/v1/issues/');
    const response = await fetch(`${API_BASE_URL}/api/v1/issues/`);
      if (!response.ok) throw new Error('Failed to fetch data.');
      const data = await response.json();
      setIssues(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  // --- UI HELPERS ---
  const getStatusUI = (status) => {
    switch (status) {
      case 'Resolved': return { classes: 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20', icon: <CheckCircle size={14} /> };
      case 'In Progress': return { classes: 'text-amber-400 bg-amber-400/10 border-amber-400/20', icon: <AlertCircle size={14} /> };
      default: return { classes: 'text-blue-400 bg-blue-400/10 border-blue-400/20', icon: <Clock size={14} /> }; // Pending
    }
  };

  const getTimeAgo = (timestamp) => {
    const diffMs = new Date() - new Date(timestamp);
    const diffDays = Math.floor(diffMs / 86400000);
    const diffHrs = Math.floor((diffMs % 86400000) / 3600000);
    const diffMins = Math.round(((diffMs % 86400000) % 3600000) / 60000);
    
    if (diffDays > 0) return `${diffDays}d ago`;
    if (diffHrs > 0) return `${diffHrs}h ago`;
    if (diffMins > 0) return `${diffMins}m ago`;
    return 'Just now';
  };

  // --- FILTERING & SORTING LOGIC ---
  const processedIssues = issues
    .filter(issue => filterStatus === 'All' || (issue.status || 'Pending') === filterStatus)
    .filter(issue => filterCategory === 'All' || (issue.category || 'Unknown') === filterCategory)
    .filter(issue => {
      if (filterDate === 'All Time') return true;
      
      const issueDate = new Date(issue.created_at);
      const today = new Date();
      
      if (filterDate === 'Today') {
        return issueDate.toDateString() === today.toDateString();
      }
      if (filterDate === 'Past 7 Days') {
        const past = new Date(today.getTime() - (7 * 24 * 60 * 60 * 1000));
        return issueDate >= past;
      }
      if (filterDate === 'Past 30 Days') {
        const past = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
        return issueDate >= past;
      }
      return true;
    })
    .sort((a, b) => {
      const dateA = new Date(a.created_at);
      const dateB = new Date(b.created_at);
      return sortBy === 'Newest' ? dateB - dateA : dateA - dateB;
    });

  return (
    <div className="min-h-screen bg-[#050505] text-white font-sans">
      
      {/* Navbar */}
      <nav className="border-b border-white/10 bg-[#0A0A0A] sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <ShieldCheck size={24} className="text-[#6B4EFF]" />
            <span className="text-xl font-bold tracking-tight">CivicFix Public</span>
          </div>
          <div className="flex items-center gap-2 px-3 py-1 bg-white/5 border border-white/10 rounded-full text-xs font-medium text-gray-400">
            <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
            Live Feed
          </div>
        </div>
      </nav>

      {/* Main Container */}
      <div className="max-w-7xl mx-auto px-6 py-12">
        
        {/* Header Stats */}
        <div className="flex flex-col md:flex-row justify-between items-end gap-6 mb-8 border-b border-white/10 pb-8">
          <div>
            <h1 className="text-4xl font-bold mb-2">City Reports</h1>
            <p className="text-gray-400">Tracking civic infrastructure issues submitted by citizens.</p>
          </div>
          <div className="flex gap-4">
            <div className="bg-[#111] border border-white/10 rounded-lg px-6 py-3 text-center">
              <p className="text-xs text-gray-500 uppercase font-bold mb-1">Total</p>
              <p className="text-2xl font-bold">{issues.length}</p>
            </div>
            <div className="bg-[#111] border border-white/10 rounded-lg px-6 py-3 text-center">
              <p className="text-xs text-gray-500 uppercase font-bold mb-1 text-emerald-400">Resolved</p>
              <p className="text-2xl font-bold">{issues.filter(i => i.status === 'Resolved').length}</p>
            </div>
          </div>
        </div>

        {/* --- FILTER CONTROL BAR --- */}
        <div className="flex flex-col md:flex-row items-start md:items-center gap-4 mb-10 bg-[#0A0A0A] p-4 rounded-xl border border-white/10">
          <div className="flex items-center gap-2 text-gray-400 mr-2">
            <Filter size={18} />
            <span className="text-sm font-semibold uppercase tracking-wider">Filters:</span>
          </div>
          
          <div className="flex flex-wrap gap-4 w-full md:w-auto">
            {/* Status Filter */}
            <select 
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="bg-[#111] border border-white/10 text-white text-sm rounded-lg focus:ring-[#6B4EFF] focus:border-[#6B4EFF] p-2.5 outline-none cursor-pointer hover:bg-white/5 transition-colors"
            >
              <option value="All">All Statuses</option>
              <option value="Pending">Pending</option>
              <option value="In Progress">In Progress</option>
              <option value="Resolved">Resolved</option>
            </select>

            {/* Category Filter */}
            <select 
              value={filterCategory}
              onChange={(e) => setFilterCategory(e.target.value)}
              className="bg-[#111] border border-white/10 text-white text-sm rounded-lg focus:ring-[#6B4EFF] focus:border-[#6B4EFF] p-2.5 outline-none cursor-pointer hover:bg-white/5 transition-colors"
            >
              <option value="All">All Departments</option>
              <option value="PWD">PWD</option>
              <option value="JSD">JSD</option>
              <option value="SMC">SMC</option>
              <option value="KPDCL">KPDCL</option>
              <option value="JKFD">JKFD</option>
            </select>

            {/* Date Filter */}
            <select 
              value={filterDate}
              onChange={(e) => setFilterDate(e.target.value)}
              className="bg-[#111] border border-white/10 text-white text-sm rounded-lg focus:ring-[#6B4EFF] focus:border-[#6B4EFF] p-2.5 outline-none cursor-pointer hover:bg-white/5 transition-colors"
            >
              <option value="All Time">All Time</option>
              <option value="Today">Today</option>
              <option value="Past 7 Days">Past 7 Days</option>
              <option value="Past 30 Days">Past 30 Days</option>
            </select>

            {/* Time Sort */}
            <select 
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="bg-[#111] border border-white/10 text-white text-sm rounded-lg focus:ring-[#6B4EFF] focus:border-[#6B4EFF] p-2.5 outline-none cursor-pointer hover:bg-white/5 transition-colors md:ml-auto"
            >
              <option value="Newest">Newest First</option>
              <option value="Oldest">Oldest First</option>
            </select>
          </div>
        </div>

        {/* LOADING & ERROR STATES */}
        {isLoading && <div className="text-center py-20 text-[#6B4EFF] animate-pulse">Loading reports...</div>}
        {error && <div className="text-center py-20 text-red-400">Error: {error}</div>}
        {!isLoading && !error && processedIssues.length === 0 && (
          <div className="text-center py-20 text-gray-500 bg-[#111] rounded-xl border border-white/10">
            No issues match your current filters.
          </div>
        )}

        {/* STRICT GRID LAYOUT */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {processedIssues.map((issue) => {
            const statusUI = getStatusUI(issue.status || 'Pending');

            return (
              <div key={issue.id} className="bg-[#0A0A0A] rounded-xl border border-white/10 overflow-hidden flex flex-col hover:border-[#6B4EFF]/50 transition-colors">
                
                {/* Image Container - STRICTLY CONSTRAINED HEIGHT */}
                <div className="h-48 w-full relative bg-[#111] border-b border-white/10">
                  {issue.image_url ? (
                    <img src={issue.image_url} alt="Report" className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center"><ImageIcon className="text-gray-700" size={32}/></div>
                  )}
                  
                  {/* Floating Category Tag ONLY */}
                  <div className="absolute top-3 left-3 px-2 py-1 bg-black/80 backdrop-blur border border-white/10 rounded text-[10px] font-bold uppercase tracking-wider">
                    {issue.category || 'UNKNOWN'}
                  </div>
                </div>

                {/* Data Container */}
                <div className="p-5 flex-1 flex flex-col">
                  {/* Description */}
                  <p className="text-sm text-gray-300 leading-relaxed line-clamp-3 flex-1 mb-4">
                    {issue.description || "No description provided by citizen."}
                  </p>

                  {/* STATUS PILL MOVED ABOVE LOCATION */}
                  <div className={`mt-auto mb-4 px-3 py-1.5 w-fit rounded border flex items-center gap-1.5 text-xs font-bold ${statusUI.classes}`}>
                    {statusUI.icon}
                    {(issue.status || 'Pending').toUpperCase()}
                  </div>

                  {/* Footer Details */}
                  <div className="flex flex-col gap-3 pt-4 border-t border-white/5">
                    
                    {/* CLICKABLE LOCATION */}
                    {issue.latitude && issue.longitude ? (
                      <a 
                        href={`https://www.google.com/maps/search/?api=1&query=${issue.latitude},${issue.longitude}`} 
                        target="_blank" 
                        rel="noopener noreferrer"
                        className="flex items-center text-xs text-[#6B4EFF] font-medium hover:text-[#9D84FF] transition-colors group cursor-pointer"
                        title="View on Google Maps"
                      >
                        <MapPin size={14} className="mr-2 flex-shrink-0" />
                        <span className="truncate group-hover:underline">
                          {issue.latitude.toFixed(4)}, {issue.longitude.toFixed(4)}
                        </span>
                        <ExternalLink size={12} className="ml-1.5 opacity-0 group-hover:opacity-100 transition-opacity" />
                      </a>
                    ) : (
                      <div className="flex items-center text-xs text-gray-500 font-medium">
                        <MapPin size={14} className="mr-2 flex-shrink-0" />
                        Location unavailable
                      </div>
                    )}

                    <div className="flex items-center text-xs text-gray-500 font-medium">
                      <Clock size={14} className="mr-2 flex-shrink-0" />
                      {getTimeAgo(issue.created_at)}
                    </div>
                  </div>
                </div>

              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}