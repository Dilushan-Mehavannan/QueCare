import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as Bull from 'bull';
import * as admin from 'firebase-admin';
import { Appointment } from '../appointments/entities/appointment.entity';
import { RedisProvider } from './redis.provider';
import { QueueGateway } from './queue.gateway';

export interface QueueStatusData {
  appointmentId: string;
  status: string;
  queueNumber: number;
  currentServing: number;
  position: number;
  peopleAhead: number;
}

@Injectable()
export class QueueService implements OnModuleInit {
  constructor(
    @InjectQueue('queue') private appointmentQueue: Bull.Queue,
    @InjectRepository(Appointment)
    private appointmentsRepository: Repository<Appointment>,
    private redisProvider: RedisProvider,
    private queueGateway: QueueGateway,
  ) {}

  async onModuleInit() {
    // Schedule repeatable check-no-shows job to run every 30 seconds in Bull queue
    await this.appointmentQueue.add(
      'check-no-shows',
      {},
      {
        repeat: { cron: '*/30 * * * * *' },
        jobId: 'check-no-shows-job',
        removeOnComplete: true,
        removeOnFail: true,
      },
    );
    console.log(
      '[QueueService] Registered repeatable Bull cron job for check-no-shows every 30s.',
    );
  }

  async addAppointmentJob(data: any) {
    await this.appointmentQueue.add('process-appointment', data);
  }

  private getRedisKey(doctorId: string): string {
    return `queue:doctor:${doctorId}`;
  }

  // Enqueue appointment in doctor's Redis list
  async enqueueAppointment(
    doctorId: string,
    appointmentId: string,
  ): Promise<number> {
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    // Push to end of list
    const listLength = await redis.rpush(key, appointmentId);
    console.log(
      `[QueueService] Enqueued appointment ${appointmentId} to Redis key ${key}. Position: ${listLength}`,
    );

    // Broadcast updated queue state
    await this.broadcastQueueState(doctorId);

    return listLength;
  }

  // Find 1-based position of appointment in doctor's Redis list
  async getQueuePosition(
    doctorId: string,
    appointmentId: string,
  ): Promise<number> {
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    const list = await redis.lrange(key, 0, -1);
    const index = list.indexOf(appointmentId);

    return index !== -1 ? index + 1 : 0;
  }

  // Retrieve active queue status details
  async getQueueStatus(appointmentId: string) {
    const appointment = await this.appointmentsRepository.findOne({
      where: { id: appointmentId },
    });

    if (!appointment) {
      throw new NotFoundException(
        `Appointment with ID ${appointmentId} not found`,
      );
    }

    const { doctorId, queueNumber, status } = appointment;
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    // Get position from Redis
    const position = await this.getQueuePosition(doctorId, appointmentId);

    // Peek at head (position 1) in Redis list to get currently serving
    const currentServingId = await redis.lindex(key, 0);
    let currentServing = 0;

    if (currentServingId) {
      const currentApt = await this.appointmentsRepository.findOne({
        where: { id: currentServingId },
      });
      if (currentApt) {
        currentServing = currentApt.queueNumber || 1;
      }
    }

    const peopleAhead = position > 0 ? position - 1 : 0;

    return {
      appointmentId,
      status,
      queueNumber: queueNumber || 0,
      currentServing,
      position, // 1-based rank inside Redis list
      peopleAhead,
    };
  }

  // Pop from front of list, update Postgres to completed, and transition next patient
  async advanceQueue(doctorId: string): Promise<string | null> {
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    // Pop the completed patient from front
    const completedAptId = await redis.lpop(key);
    if (completedAptId) {
      console.log(
        `[QueueService] Popped appointment ${completedAptId} (completed) from doctor ${doctorId} queue.`,
      );
      await this.appointmentsRepository.update(completedAptId, {
        status: 'completed',
      });
    }

    // Transition next patient in Redis (new index 0) to 'in_queue'
    const nextAptId = await redis.lindex(key, 0);
    if (nextAptId) {
      const nextApt = await this.appointmentsRepository.findOne({
        where: { id: nextAptId },
      });
      if (nextApt && nextApt.status === 'pending') {
        nextApt.status = 'in_queue';
        await this.appointmentsRepository.save(nextApt);
        console.log(
          `[QueueService] Transitioned next patient ${nextAptId} status to 'in_queue'`,
        );
      }
    }

    // Broadcast the updated queue status to doctor's room
    await this.broadcastQueueState(doctorId);

    return completedAptId;
  }

  // Remove appointment from Redis queue entirely, and mark as skipped
  async skipAppointment(
    doctorId: string,
    appointmentId: string,
  ): Promise<void> {
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    // Find position of skipped appointment before removing
    const position = await this.getQueuePosition(doctorId, appointmentId);

    // Remove appointmentId from Redis list
    await redis.lrem(key, 0, appointmentId);
    console.log(
      `[QueueService] Removed appointment ${appointmentId} (skipped) from doctor ${doctorId} queue.`,
    );

    // Update status to skipped in PostgreSQL
    await this.appointmentsRepository.update(appointmentId, {
      status: 'skipped',
    });

    // If it was position 1 (head), transition the new position 1 (if any) to 'in_queue'
    if (position === 1) {
      const nextAptId = await redis.lindex(key, 0);
      if (nextAptId) {
        const nextApt = await this.appointmentsRepository.findOne({
          where: { id: nextAptId },
        });
        if (
          nextApt &&
          (nextApt.status === 'pending' || nextApt.status === 'in_queue')
        ) {
          nextApt.status = 'in_queue';
          await this.appointmentsRepository.save(nextApt);
          console.log(
            `[QueueService] Head patient skipped. Transitioned new head patient ${nextAptId} to 'in_queue'`,
          );
        }
      }
    }

    // Broadcast the updated queue status
    await this.broadcastQueueState(doctorId);
  }

  // Helper to fetch list of doctor's active queues and broadcast positions
  async broadcastQueueState(doctorId: string) {
    const redis = this.redisProvider.getClient();
    const key = this.getRedisKey(doctorId);

    const list = await redis.lrange(key, 0, -1);

    // Broadcast for each appointment inside the queue
    for (let i = 0; i < list.length; i++) {
      const aptId = list[i];
      try {
        const statusData = await this.getQueueStatus(aptId);
        this.queueGateway.emitQueueUpdate(doctorId, statusData);

        // Check and trigger Leave Now alert if patient moves to position 3
        if (statusData.position === 3) {
          await this.checkAndTriggerLeaveNowAlert(aptId, statusData);
        }
      } catch (err) {
        console.error(
          `[QueueService] Failed to broadcast queue state for appointment ${aptId}:`,
          err,
        );
      }
    }
  }

  // Return a list of all active doctor keys in Redis
  async getActiveDoctors(): Promise<string[]> {
    const redis = this.redisProvider.getClient();
    const keys = await redis.keys('queue:doctor:*');
    return keys.map((key) => key.replace('queue:doctor:', ''));
  }

  // Leave Now Alert calculation using Google Maps Directions API and FCM Push notification
  async checkAndTriggerLeaveNowAlert(
    appointmentId: string,
    statusData: QueueStatusData,
  ) {
    console.log(
      `[QueueService] Checking Leave Now alert for appointment ${appointmentId} at position ${statusData.position}`,
    );

    const appointment = await this.appointmentsRepository.findOne({
      where: { id: appointmentId },
    });

    if (!appointment) return;

    // Origins and destinations
    const lat = appointment.lastLatitude || 40.7128;
    const lng = appointment.lastLongitude || -74.006;
    const destination = appointment.clinicName || 'Metro Care General Hospital';

    const apiKey = process.env.GOOGLE_MAPS_API_KEY || '';
    let travelDurationMinutes = 15; // fallback simulated travel duration

    if (apiKey) {
      try {
        const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${lat},${lng}&destination=${encodeURIComponent(destination)}&key=${apiKey}`;
        const response = await fetch(url);
        const data = (await response.json()) as {
          status: string;
          routes?: Array<{
            legs: Array<{
              duration: {
                value: number;
              };
            }>;
          }>;
        };

        if (
          data.status === 'OK' &&
          data.routes &&
          data.routes[0] &&
          data.routes[0].legs &&
          data.routes[0].legs[0]
        ) {
          const durationSeconds = data.routes[0].legs[0].duration.value;
          travelDurationMinutes = Math.ceil(durationSeconds / 60);
          console.log(
            `[QueueService] Google Maps Directions travel duration: ${travelDurationMinutes} minutes`,
          );
        } else {
          console.warn(
            `[QueueService] Google Maps directions API status not OK: ${data.status}. Using fallback 15 mins.`,
          );
        }
      } catch (err) {
        console.error(`[QueueService] Failed to call Directions API:`, err);
      }
    } else {
      console.log(
        `[QueueService] GOOGLE_MAPS_API_KEY not configured. Using fallback travel time: 15 mins.`,
      );
    }

    // Est. Wait = peopleAhead * 5 minutes
    const peopleAhead = statusData.peopleAhead || 0;
    const estimatedWaitMinutes = peopleAhead * 5;

    console.log(
      `[QueueService] Compare travel duration (${travelDurationMinutes}m) with est. wait (${estimatedWaitMinutes}m)`,
    );

    // If travel duration is more than estimated wait time, send FCM
    if (travelDurationMinutes > estimatedWaitMinutes) {
      console.log(
        `[QueueService] Triggering "Leave Now" alert! Travel duration exceeds estimated wait.`,
      );

      const token = appointment.fcmToken || 'mock-fcm-token-123';
      const notificationPayload = {
        token,
        notification: {
          title: 'Leave Now Alert 🚗',
          body: `Head out immediately! Estimated travel time is ${travelDurationMinutes} mins, but wait time at ${destination} is only ${estimatedWaitMinutes} mins.`,
        },
        data: {
          appointmentId: appointment.id,
          type: 'LEAVE_NOW',
          travelDuration: String(travelDurationMinutes),
          estimatedWait: String(estimatedWaitMinutes),
        },
      };

      try {
        if (admin.apps.length > 0) {
          await admin.messaging().send(notificationPayload);
          console.log(
            `[QueueService] FCM "Leave Now" notification successfully sent to device.`,
          );
        } else {
          console.log(
            `[QueueService Mock Mode] FCM Notification triggered:`,
            notificationPayload,
          );
        }
      } catch (err) {
        console.error(`[QueueService] Failed to send FCM messaging:`, err);
      }
    }
  }
}
