import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine } from 'recharts';
import { TrendingUp, Users, Clock, Zap, AlertCircle } from 'lucide-react';

const API_BASE = 'http://localhost:3000';

interface AnalyticsData {
  hour: string;
  waitTime: number;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{
    value: number;
    payload: AnalyticsData;
  }>;
}

// Custom tooltips styling
const CustomTooltip = ({ active, payload }: CustomTooltipProps) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-slate-950/95 text-white p-3.5 rounded-xl border border-slate-800 shadow-2xl backdrop-blur-md">
        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-widest">
          Clinic Hour: {payload[0].payload.hour}
        </p>
        <div className="flex items-center gap-2 mt-1.5">
          <span className="w-2 h-2 rounded-full bg-mint-400 pulse-glow-teal"></span>
          <p className="text-sm font-extrabold text-slate-100">
            Avg. Wait: <span className="text-mint-400">{payload[0].value} mins</span>
          </p>
        </div>
      </div>
    );
  }
  return null;
};

export default function AnalyticsPage() {
  const { data: analytics = [], isLoading, error } = useQuery<AnalyticsData[]>({
    queryKey: ['analytics'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE}/appointments/analytics`, {
        headers: { Authorization: 'Bearer admin' },
      });
      return response.data;
    },
  });

  // Calculate high-fidelity aggregate stats
  const averageWaitTime = analytics.length
    ? Math.round(analytics.reduce((acc, curr) => acc + curr.waitTime, 0) / analytics.length)
    : 0;

  const peakHourObj = analytics.length
    ? [...analytics].sort((a, b) => b.waitTime - a.waitTime)[0]
    : null;

  const peakHour = peakHourObj ? peakHourObj.hour : 'N/A';

  return (
    <div className="space-y-8">
      {/* Top Cards row */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-primary-50 p-3 rounded-xl text-primary-600">
            <Clock className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Average Wait Time
            </span>
            <h4 className="font-outfit font-extrabold text-xl text-slate-800 mt-1">
              {averageWaitTime} minutes
            </h4>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-amber-50 p-3 rounded-xl text-amber-600">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Peak Traffic Hour
            </span>
            <h4 className="font-outfit font-extrabold text-xl text-slate-800 mt-1">
              {peakHour}
            </h4>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-mint-50 p-3 rounded-xl text-mint-600">
            <Zap className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Target Wait Limit
            </span>
            <h4 className="font-outfit font-extrabold text-xl text-slate-800 mt-1">
              15 mins
            </h4>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-4">
          <div className="bg-blue-50 p-3 rounded-xl text-blue-600">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
              Operational Rating
            </span>
            <h4 className="font-outfit font-extrabold text-xl text-slate-800 mt-1">
              A+ Excellent
            </h4>
          </div>
        </div>
      </div>

      {/* Recharts Analytics Panel */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h3 className="font-outfit font-extrabold text-lg text-slate-800">
              Weekly Wait Time Distribution (Hourly Index)
            </h3>
            <p className="text-slate-400 text-xs mt-1">
              Tracks the average consultation wait times of checking patients across past 7 business days.
            </p>
          </div>
          <span className="px-3.5 py-1 text-xs font-bold bg-mint-50 text-mint-700 rounded-full border border-mint-200/50">
            Live Diagnostics
          </span>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center h-80">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600"></div>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center h-80 text-center text-slate-400">
            <AlertCircle className="w-10 h-10 text-red-500 mb-2" />
            <p className="font-semibold">Unable to Load Chart Data</p>
            <p className="text-xs">Ensure your database API and seeds are active.</p>
          </div>
        ) : (
          <div className="h-96 w-full -ml-3">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={analytics}>
                {/* SVG Glowing Line Shadow Filter Definition */}
                <defs>
                  <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
                    <feDropShadow dx="0" dy="8" stdDeviation="4" floodColor="#14b8a6" floodOpacity="0.25" />
                  </filter>
                </defs>

                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis
                  dataKey="hour"
                  stroke="#94a3b8"
                  fontSize={10}
                  fontWeight={600}
                  tickLine={false}
                  axisLine={false}
                  dy={10}
                />
                <YAxis
                  stroke="#94a3b8"
                  fontSize={10}
                  fontWeight={600}
                  tickLine={false}
                  axisLine={false}
                  dx={-10}
                  label={{ value: 'Avg Wait (mins)', angle: -90, position: 'insideLeft', offset: 0, style: { fill: '#64748b', fontSize: 10, fontWeight: 700 } }}
                />
                <Tooltip content={<CustomTooltip />} cursor={{ stroke: '#cbd5e1', strokeWidth: 1.5, strokeDasharray: '4 4' }} />
                
                {/* Standard wait time threshold line */}
                <ReferenceLine y={15} stroke="#ec4899" strokeWidth={1.5} strokeDasharray="3 3" label={{ value: 'Target Max (15m)', fill: '#db2777', fontSize: 9, fontWeight: 700, position: 'insideBottomRight' }} />

                <Line
                  type="monotone"
                  dataKey="waitTime"
                  stroke="url(#colorTeal)"
                  strokeWidth={4.5}
                  dot={{ r: 5, strokeWidth: 3.5, stroke: '#ffffff', fill: '#0d9488' }}
                  activeDot={{ r: 8, strokeWidth: 0, fill: '#10b981' }}
                  filter="url(#glow)"
                />

                {/* Support dual gradients */}
                <defs>
                  <linearGradient id="colorTeal" x1="0" y1="0" x2="1" y2="0">
                    <stop offset="0%" stopColor="#0f766e" />
                    <stop offset="100%" stopColor="#10b981" />
                  </linearGradient>
                </defs>
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
    </div>
  );
}
