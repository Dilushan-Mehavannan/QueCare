import { Process, Processor } from '@nestjs/bull';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from '../appointments/entities/appointment.entity';
import { QueueService } from './queue.service';
import { RedisProvider } from './redis.provider';

@Processor('queue')
export class NoShowProcessor {
  constructor(
    @InjectRepository(Appointment)
    private appointmentsRepository: Repository<Appointment>,
    private queueService: QueueService,
    private redisProvider: RedisProvider,
  ) {}

  @Process('check-no-shows')
  async handleCheckNoShows() {
    console.log('[NoShowProcessor] Executing recurring check for no-shows...');

    try {
      const activeDoctors = await this.queueService.getActiveDoctors();
      const redis = this.redisProvider.getClient();

      for (const doctorId of activeDoctors) {
        const key = `queue:doctor:${doctorId}`;
        // Peek at position 1 (index 0) in Redis list
        const headAptId = await redis.lindex(key, 0);

        if (headAptId) {
          const appointment = await this.appointmentsRepository.findOne({
            where: { id: headAptId },
          });

          if (appointment) {
            // Check if patient has checked-in (arrived)
            if (!appointment.arrivedAt) {
              const slotDate = this.parseSlotToDate(
                appointment.appointmentDate,
                appointment.appointmentTime,
              );

              // Calculate how many minutes have passed since the slot start time
              const elapsedMinutes = (Date.now() - slotDate.getTime()) / 60000;

              if (elapsedMinutes > 10) {
                console.warn(
                  `[NoShowProcessor] Patient skipped: Appointment ${appointment.id} (Doctor ${doctorId}) at Position 1 missed arrival deadline by ${Math.floor(elapsedMinutes)} minutes.`,
                );

                // Mark skipped and advance queue
                await this.queueService.skipAppointment(
                  doctorId,
                  appointment.id,
                );
              }
            }
          }
        }
      }
    } catch (err) {
      console.error('[NoShowProcessor] Failed to execute no-show checks:', err);
    }
  }

  // Parse patient slot inputs e.g. date: 'Today'/'Tomorrow'/'2026-06-01' and time: '10:30 AM' into real Date object
  private parseSlotToDate(dateStr: string, timeStr: string): Date {
    const now = new Date();
    let baseDate = new Date();

    if (dateStr.toLowerCase() === 'today') {
      baseDate = now;
    } else if (dateStr.toLowerCase() === 'tomorrow') {
      baseDate = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    } else {
      const parsed = Date.parse(dateStr);
      if (!isNaN(parsed)) {
        baseDate = new Date(parsed);
      }
    }

    const match = timeStr.match(/^(\d+):(\d+)\s*(AM|PM)$/i);
    if (match) {
      let hours = parseInt(match[1]);
      const minutes = parseInt(match[2]);
      const ampm = match[3].toUpperCase();

      if (ampm === 'PM' && hours < 12) hours += 12;
      if (ampm === 'AM' && hours === 12) hours = 0;

      baseDate.setHours(hours, minutes, 0, 0);
    }

    return baseDate;
  }
}
