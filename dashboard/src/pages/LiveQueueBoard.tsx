import { useEffect, useState } from 'react';
import axios from 'axios';
import { io } from 'socket.io-client';
import { User, UserX, UserCheck, Activity } from 'lucide-react';

const API_BASE = 'http://localhost:3000';

interface Doctor {
  id: string;
  name: string;
  specialty: string;
  imageUrl: string;
  rating: number;
}

interface Appointment {
  id: string;
  doctorId: string;
  doctorName: string;
  clinicName: string;
  appointmentTime: string;
  appointmentDate: string;
  status: 'pending' | 'in_queue' | 'completed' | 'skipped';
  queueNumber: number;
  lastLatitude?: number;
  lastLongitude?: number;
}

const DOCTORS: Doctor[] = [
  {
    id: 'd1',
    name: 'Dr. Sarah Jenkins',
    specialty: 'General Practitioner',
    imageUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&auto=format&fit=crop',
    rating: 4.9,
  },
  {
    id: 'd3',
    name: 'Dr. Elena Rostova',
    specialty: 'Pediatric Dentist',
    imageUrl: 'https://images.unsplash.com/photo-1594824813573-246434de83fb?w=400&auto=format&fit=crop',
    rating: 4.7,
  },
  {
    id: 'd2',
    name: 'Dr. Marcus Vance',
    specialty: 'Cardiologist',
    imageUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&auto=format&fit=crop',
    rating: 4.8,
  }
];

export default function LiveQueueBoard() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [connected, setConnected] = useState(false);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // 1. Fetch initial appointments
  const fetchAppointments = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`${API_BASE}/appointments/all`, {
        headers: { Authorization: 'Bearer admin' },
      });
      setAppointments(response.data);
    } catch (err) {
      console.error('Failed to load appointments:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // 1. Fetch initial appointments deferred to avoid synchronous setState inside effect
    const timer = setTimeout(() => {
      fetchAppointments().catch((err) => console.error(err));
    }, 0);

    // 2. Setup Socket.IO real-time subscriptions
    const socketInstance = io(API_BASE, {
      transports: ['websocket'],
    });

    socketInstance.on('connect', () => {
      console.log('[Socket] Connected to NestJS');
      setConnected(true);
      
      // Subscribe to updates for all target doctors
      DOCTORS.forEach((doc) => {
        socketInstance.emit('subscribeToDoctor', { doctorId: doc.id });
      });
    });

    socketInstance.on('disconnect', () => {
      console.log('[Socket] Disconnected');
      setConnected(false);
    });

    // 3. Handle live positions, serving numbers and skipped states broadcast
    socketInstance.on('queue-update', (data: unknown) => {
      console.log('[Socket] Live Queue Update received:', data);
      
      // Re-trigger an appointment fetch when queue events update
      // this is highly robust as it pulls authoritative postgres state
      fetchAppointments().catch((err) => console.error(err));
    });

    return () => {
      clearTimeout(timer);
      DOCTORS.forEach((doc) => {
        socketInstance.emit('unsubscribeFromDoctor', { doctorId: doc.id });
      });
      socketInstance.disconnect();
    };
  }, []);

  // 4. Advance queue (Call Next)
  const handleCallNext = async (doctorId: string) => {
    try {
      setActionLoading(`${doctorId}-advance`);
      await axios.post(`${API_BASE}/queue/${doctorId}/advance`, {}, {
        headers: { Authorization: 'Bearer admin' },
      });
      fetchAppointments();
    } catch (err) {
      console.error('Failed to call next patient:', err);
    } finally {
      setActionLoading(null);
    }
  };

  // 5. Skip Patient
  const handleSkipPatient = async (doctorId: string, appointmentId: string) => {
    try {
      setActionLoading(`${appointmentId}-skip`);
      await axios.post(`${API_BASE}/queue/${doctorId}/skip/${appointmentId}`, {}, {
        headers: { Authorization: 'Bearer admin' },
      });
      fetchAppointments();
    } catch (err) {
      console.error('Failed to skip patient:', err);
    } finally {
      setActionLoading(null);
    }
  };

  const getDoctorQueue = (doctorId: string) => {
    return appointments
      .filter((apt) => apt.doctorId === doctorId && (apt.status === 'in_queue' || apt.status === 'pending'))
      .sort((a, b) => a.queueNumber - b.queueNumber);
  };

  return (
    <div className="space-y-8">
      {/* Real-time Indicator Header */}
      <div className="flex items-center justify-between bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
        <div>
          <h3 className="font-outfit font-extrabold text-xl text-slate-800">
            Real-Time Clinic Feed
          </h3>
          <p className="text-slate-500 text-sm mt-1">
            Displaying patient streams and queue lists synced live over WebSockets.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className={`w-3 h-3 rounded-full ${connected ? 'bg-mint-500 pulse-glow-teal' : 'bg-red-500 pulse-glow-red'}`}></span>
          <span className="text-sm font-semibold text-slate-700 capitalize">
            {connected ? 'WS Connection Active' : 'WS Reconnecting...'}
          </span>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {DOCTORS.map((doc) => {
            const queue = getDoctorQueue(doc.id);
            const activePatient = queue.find((apt) => apt.status === 'in_queue');
            const waitingPatients = queue.filter((apt) => apt.status === 'pending');

            return (
              <div key={doc.id} className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm hover:shadow-md transition-shadow duration-200 flex flex-col h-[640px]">
                {/* Doctor Bio Card Header */}
                <div className="p-5 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-950 text-white flex items-center gap-4 relative">
                  <img
                    src={doc.imageUrl}
                    alt={doc.name}
                    className="w-14 h-14 rounded-xl object-cover border border-slate-700"
                  />
                  <div>
                    <h4 className="font-outfit font-bold text-base leading-tight">
                      {doc.name}
                    </h4>
                    <p className="text-xs text-primary-300 font-medium mt-1">
                      {doc.specialty}
                    </p>
                    <div className="flex items-center gap-1 mt-1 text-[11px] text-slate-400">
                      <span>★ {doc.rating} Rating</span>
                    </div>
                  </div>
                  <span className="absolute top-4 right-4 bg-primary-500/20 text-primary-400 text-[10px] font-bold px-2 py-0.5 rounded-full border border-primary-500/30">
                    Feed Live
                  </span>
                </div>

                {/* Queue Control Buttons */}
                <div className="p-4 bg-slate-50 border-b border-slate-100 flex gap-2 flex-shrink-0">
                  <button
                    onClick={() => handleCallNext(doc.id)}
                    disabled={queue.length === 0 || actionLoading !== null}
                    className="flex-1 flex items-center justify-center gap-2 bg-primary-700 hover:bg-primary-800 disabled:bg-slate-200 disabled:text-slate-400 text-white py-2.5 px-4 rounded-xl text-xs font-bold transition-all shadow-sm"
                  >
                    {actionLoading === `${doc.id}-advance` ? (
                      <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                    ) : (
                      <UserCheck className="w-4 h-4" />
                    )}
                    <span>Call Next Patient</span>
                  </button>
                </div>

                {/* Active Patient Block */}
                <div className="p-5 border-b border-slate-100 bg-mint-50/20 flex-shrink-0">
                  <div className="flex items-center justify-between mb-3.5">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                      Active In Room
                    </span>
                    {activePatient && (
                      <span className="px-2 py-0.5 rounded-full bg-mint-100 text-mint-700 text-[9px] font-bold uppercase tracking-wider animate-pulse-slow">
                        Consultation Active
                      </span>
                    )}
                  </div>

                  {activePatient ? (
                    <div className="flex items-center gap-3 bg-white p-3.5 rounded-xl border border-mint-200/60 shadow-sm relative overflow-hidden">
                      <div className="absolute top-0 left-0 bottom-0 w-1.5 bg-mint-500"></div>
                      <div className="w-10 h-10 rounded-lg bg-mint-50 flex items-center justify-center text-mint-600 font-bold border border-mint-100">
                        #{activePatient.queueNumber}
                      </div>
                      <div>
                        <h5 className="font-bold text-sm text-slate-800">
                          Active Patient Room Pass
                        </h5>
                        <p className="text-[11px] text-slate-500 mt-0.5">
                          Time Slot: {activePatient.appointmentTime}
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="flex flex-col items-center justify-center py-5 bg-slate-50/50 border border-dashed border-slate-200 rounded-xl">
                      <Activity className="h-5 w-5 text-slate-300 animate-pulse" />
                      <p className="text-[11px] text-slate-400 font-medium mt-1">
                        Doctor Room Empty
                      </p>
                    </div>
                  )}
                </div>

                {/* Patient Waitlist */}
                <div className="flex-1 overflow-y-auto p-5">
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block mb-4">
                    Waitlist Queue ({waitingPatients.length})
                  </span>

                  {waitingPatients.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full text-center opacity-60">
                      <User className="h-8 w-8 text-slate-300" />
                      <p className="text-xs font-semibold text-slate-400 mt-2">
                        No Patients in Queue
                      </p>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {waitingPatients.map((apt, index) => (
                        <div
                          key={apt.id}
                          className="flex items-center justify-between bg-white p-3.5 rounded-xl border border-slate-200 hover:border-primary-200 hover:bg-primary-50/5 transition-all duration-200 shadow-sm group"
                        >
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-lg bg-slate-100 flex items-center justify-center text-slate-600 text-xs font-bold border border-slate-200">
                              #{apt.queueNumber}
                            </div>
                            <div>
                              <div className="flex items-center gap-1.5">
                                <span className="font-bold text-xs text-slate-800">
                                  Position {index + 1}
                                </span>
                                {index === 2 && (
                                  <span className="px-1.5 py-0.5 text-[8px] font-extrabold bg-amber-100 text-amber-800 rounded uppercase tracking-wider animate-pulse-slow">
                                    Trigger Spot
                                  </span>
                                )}
                              </div>
                              <p className="text-[10px] text-slate-500 mt-0.5">
                                Slot: {apt.appointmentTime}
                              </p>
                            </div>
                          </div>

                          <div className="flex items-center gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                            <button
                              onClick={() => handleSkipPatient(doc.id, apt.id)}
                              disabled={actionLoading !== null}
                              title="Skip Patient"
                              className="p-1.5 hover:bg-red-50 text-slate-400 hover:text-red-500 rounded-lg transition-colors border border-transparent hover:border-red-200"
                            >
                              {actionLoading === `${apt.id}-skip` ? (
                                <span className="w-3.5 h-3.5 border border-red-500 border-t-transparent rounded-full animate-spin block"></span>
                              ) : (
                                <UserX className="w-3.5 h-3.5" />
                              )}
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
