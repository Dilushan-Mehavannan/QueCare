import { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Activity, Calendar, BarChart3, LayoutDashboard, HeartPulse } from 'lucide-react';
import LiveQueueBoard from './pages/LiveQueueBoard';
import AppointmentsPage from './pages/AppointmentsPage';
import AnalyticsPage from './pages/AnalyticsPage';

// Initialize React Query Client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

type Tab = 'live-queue' | 'appointments' | 'analytics';

function App() {
  const [activeTab, setActiveTab] = useState<Tab>('live-queue');

  const renderActivePage = () => {
    switch (activeTab) {
      case 'live-queue':
        return <LiveQueueBoard />;
      case 'appointments':
        return <AppointmentsPage />;
      case 'analytics':
        return <AnalyticsPage />;
      default:
        return <LiveQueueBoard />;
    }
  };

  return (
    <QueryClientProvider client={queryClient}>
      <div className="flex h-screen bg-slate-50 text-slate-900 font-sans overflow-hidden">
        {/* Navigation Sidebar */}
        <aside className="w-64 bg-slate-900 text-white flex flex-col justify-between shadow-xl">
          <div>
            {/* Logo */}
            <div className="h-20 flex items-center px-6 border-b border-slate-800 gap-3">
              <div className="bg-primary-500 p-2.5 rounded-xl text-white shadow-lg shadow-primary-500/30">
                <HeartPulse className="h-6 w-6" />
              </div>
              <div>
                <h1 className="font-outfit font-extrabold text-xl tracking-tight leading-none bg-gradient-to-r from-primary-400 to-mint-400 bg-clip-text text-transparent">
                  QueueCare
                </h1>
                <span className="text-[10px] text-slate-400 font-medium uppercase tracking-widest mt-1 block">
                  Clinic Admin
                </span>
              </div>
            </div>

            {/* Menu Links */}
            <nav className="p-4 space-y-1">
              <button
                onClick={() => setActiveTab('live-queue')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium text-sm ${
                  activeTab === 'live-queue'
                    ? 'bg-primary-700 text-white shadow-lg shadow-primary-700/20'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Activity className="h-4 w-4" />
                <span>Live Queue Board</span>
                {activeTab === 'live-queue' && (
                  <span className="ml-auto w-2 h-2 rounded-full bg-mint-400 pulse-glow-teal"></span>
                )}
              </button>

              <button
                onClick={() => setActiveTab('appointments')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium text-sm ${
                  activeTab === 'appointments'
                    ? 'bg-primary-700 text-white shadow-lg shadow-primary-700/20'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Calendar className="h-4 w-4" />
                <span>Appointments</span>
              </button>

              <button
                onClick={() => setActiveTab('analytics')}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium text-sm ${
                  activeTab === 'analytics'
                    ? 'bg-primary-700 text-white shadow-lg shadow-primary-700/20'
                    : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <BarChart3 className="h-4 w-4" />
                <span>Analytics Monitor</span>
              </button>
            </nav>
          </div>

          {/* Connected User Badge */}
          <div className="p-4 border-t border-slate-800">
            <div className="flex items-center gap-3 bg-slate-800/40 p-3.5 rounded-xl border border-slate-800">
              <div className="w-9 h-9 rounded-lg bg-mint-500/10 border border-mint-500/20 flex items-center justify-center text-mint-400 font-semibold text-sm">
                AD
              </div>
              <div>
                <p className="text-xs font-semibold text-slate-200">Clinic Admin</p>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-mint-400 pulse-glow-teal"></span>
                  <span className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">
                    Dev Mock Active
                  </span>
                </div>
              </div>
            </div>
          </div>
        </aside>

        {/* Main Content Area */}
        <main className="flex-1 flex flex-col overflow-hidden bg-slate-50">
          {/* Header */}
          <header className="h-20 bg-white border-b border-slate-200 px-8 flex items-center justify-between shadow-sm flex-shrink-0 z-10">
            <div className="flex items-center gap-2">
              <LayoutDashboard className="h-5 w-5 text-slate-400" />
              <h2 className="font-outfit font-bold text-lg text-slate-800 capitalize">
                {activeTab.replace('-', ' ')}
              </h2>
            </div>
            <div className="flex items-center gap-3">
              <span className="px-3 py-1 text-xs font-bold bg-primary-50 text-primary-700 rounded-full border border-primary-100">
                Clinic: Metro Care Hospital
              </span>
              <span className="px-3 py-1 text-xs font-bold bg-slate-100 text-slate-700 rounded-full border border-slate-200">
                Server: Online
              </span>
            </div>
          </header>

          {/* Render Active View */}
          <div className="flex-1 overflow-y-auto p-8 relative">
            {renderActivePage()}
          </div>
        </main>
      </div>
    </QueryClientProvider>
  );
}

export default App;
