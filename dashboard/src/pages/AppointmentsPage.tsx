import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';
import { Search, RefreshCw, CalendarRange, Clock, Filter, AlertCircle } from 'lucide-react';

const API_BASE = 'http://localhost:3000';

interface Appointment {
  id: string;
  doctorId: string;
  doctorName: string;
  doctorSpecialty: string;
  clinicName: string;
  appointmentTime: string;
  appointmentDate: string;
  status: 'pending' | 'in_queue' | 'completed' | 'skipped';
  queueNumber: number;
  userId: string;
  createdAt: string;
}

export default function AppointmentsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'in_queue' | 'completed' | 'skipped'>('all');

  // Fetch today's all appointments
  const { data: appointments = [], isLoading, error, refetch, isFetching } = useQuery<Appointment[]>({
    queryKey: ['appointments'],
    queryFn: async () => {
      const response = await axios.get(`${API_BASE}/appointments/all`, {
        headers: { Authorization: 'Bearer admin' },
      });
      return response.data;
    },
  });

  // Calculate statistics metrics from database appointments
  const totalCount = appointments.length;
  const pendingCount = appointments.filter((a) => a.status === 'pending').length;
  const activeCount = appointments.filter((a) => a.status === 'in_queue').length;
  const completedCount = appointments.filter((a) => a.status === 'completed').length;
  const skippedCount = appointments.filter((a) => a.status === 'skipped').length;

  // Perform search and filter
  const filteredAppointments = appointments.filter((apt) => {
    const matchesSearch =
      apt.doctorName.toLowerCase().includes(search.toLowerCase()) ||
      apt.userId.toLowerCase().includes(search.toLowerCase()) ||
      apt.clinicName.toLowerCase().includes(search.toLowerCase());

    const matchesStatus = statusFilter === 'all' ? true : apt.status === statusFilter;

    return matchesSearch && matchesStatus;
  });

  const getStatusStyle = (status: Appointment['status']) => {
    switch (status) {
      case 'pending':
        return 'bg-amber-50 text-amber-700 border-amber-200/60';
      case 'in_queue':
        return 'bg-blue-50 text-blue-700 border-blue-200/60';
      case 'completed':
        return 'bg-mint-50 text-mint-700 border-mint-200/60';
      case 'skipped':
        return 'bg-red-50 text-red-700 border-red-200/60';
      default:
        return 'bg-slate-50 text-slate-700 border-slate-200/60';
    }
  };

  return (
    <div className="space-y-8">
      {/* Metrics Row */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-5">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Total Bookings
          </span>
          <h4 className="font-outfit font-extrabold text-2xl text-slate-800 mt-2">
            {totalCount}
          </h4>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Pending Queue
          </span>
          <h4 className="font-outfit font-extrabold text-2xl text-amber-600 mt-2">
            {pendingCount}
          </h4>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Active Consulting
          </span>
          <h4 className="font-outfit font-extrabold text-2xl text-blue-600 mt-2">
            {activeCount}
          </h4>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Completed Visits
          </span>
          <h4 className="font-outfit font-extrabold text-2xl text-mint-600 mt-2">
            {completedCount}
          </h4>
        </div>
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm col-span-2 lg:col-span-1">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
            Skipped No-Shows
          </span>
          <h4 className="font-outfit font-extrabold text-2xl text-red-600 mt-2">
            {skippedCount}
          </h4>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col md:flex-row gap-4 items-center justify-between">
        {/* Search */}
        <div className="relative w-full md:w-80">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search doctor or patient UID..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 hover:border-slate-300 focus:border-primary-500 rounded-xl py-2 pl-10 pr-4 text-sm font-medium transition-all"
          />
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-2 items-center w-full md:w-auto justify-start md:justify-end">
          <span className="text-xs font-bold text-slate-400 flex items-center gap-1.5 mr-2">
            <Filter className="w-3.5 h-3.5" /> Filter:
          </span>
          {(['all', 'pending', 'in_queue', 'completed', 'skipped'] as const).map((filter) => (
            <button
              key={filter}
              onClick={() => setStatusFilter(filter)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold capitalize border transition-all ${
                statusFilter === filter
                  ? 'bg-primary-700 border-primary-700 text-white shadow-sm shadow-primary-700/10'
                  : 'bg-white border-slate-200 hover:bg-slate-50 text-slate-600'
              }`}
            >
              {filter.replace('_', ' ')}
            </button>
          ))}
          
          <button
            onClick={() => refetch()}
            disabled={isFetching}
            className="p-2 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-600 transition-colors ml-2"
            title="Refresh list"
          >
            <RefreshCw className={`h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Main Table Grid */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
        {isLoading ? (
          <div className="flex items-center justify-center py-24">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600"></div>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-20 text-center text-slate-400">
            <AlertCircle className="w-10 h-10 text-red-500 mb-2" />
            <p className="font-semibold">Failed to Fetch Appointments</p>
            <p className="text-xs text-slate-400 mt-1">Please ensure the NestJS API server is online.</p>
          </div>
        ) : filteredAppointments.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center text-slate-400">
            <CalendarRange className="w-12 h-12 text-slate-200 mb-2 animate-bounce" />
            <p className="font-semibold text-slate-500">No Appointments Match Search Filters</p>
            <p className="text-xs mt-1">Try updating your status selection or query terms.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold tracking-wider border-b border-slate-200">
                  <th className="py-4 px-6">Queue #</th>
                  <th className="py-4 px-6">Patient (UID)</th>
                  <th className="py-4 px-6">Doctor Stream</th>
                  <th className="py-4 px-6">Scheduled Time</th>
                  <th className="py-4 px-6">Status Badge</th>
                  <th className="py-4 px-6">Booking Date</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs font-semibold text-slate-700">
                {filteredAppointments.map((apt) => (
                  <tr key={apt.id} className="hover:bg-slate-50/50 transition-colors">
                    <td className="py-4.5 px-6">
                      <span className="w-8 h-8 rounded-lg bg-slate-100 border border-slate-200 flex items-center justify-center font-bold text-slate-600">
                        #{apt.queueNumber}
                      </span>
                    </td>
                    <td className="py-4.5 px-6">
                      <div className="flex items-center gap-2">
                        <div className="w-6 h-6 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 font-bold border border-slate-200 text-[10px]">
                          P
                        </div>
                        <span className="font-mono text-slate-800 font-bold max-w-[120px] truncate block" title={apt.userId}>
                          {apt.userId}
                        </span>
                      </div>
                    </td>
                    <td className="py-4.5 px-6">
                      <div>
                        <p className="font-bold text-slate-800">{apt.doctorName}</p>
                        <p className="text-[10px] text-slate-400 font-medium mt-0.5">{apt.doctorSpecialty}</p>
                      </div>
                    </td>
                    <td className="py-4.5 px-6">
                      <div className="flex items-center gap-1.5 text-slate-600 font-medium">
                        <Clock className="w-3.5 h-3.5 text-slate-400" />
                        <span>{apt.appointmentTime}</span>
                      </div>
                    </td>
                    <td className="py-4.5 px-6">
                      <span className={`px-2.5 py-1 rounded-full border text-[10px] font-extrabold uppercase tracking-wider ${getStatusStyle(apt.status)}`}>
                        {apt.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="py-4.5 px-6">
                      <span className="text-[10px] text-slate-400 font-medium">
                        {apt.appointmentDate}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
