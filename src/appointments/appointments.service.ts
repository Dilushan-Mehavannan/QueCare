import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment } from './entities/appointment.entity';
import { BookAppointmentDto } from './dto/book-appointment.dto';
import { QueueService } from '../queue/queue.service';

@Injectable()
export class AppointmentsService {
  constructor(
    @InjectRepository(Appointment)
    private appointmentsRepository: Repository<Appointment>,
    private queueService: QueueService,
  ) {}

  async bookAppointment(
    userId: string,
    dto: BookAppointmentDto,
  ): Promise<Appointment> {
    // Calculate the next queue number for this doctor on this date
    const lastAppointment = await this.appointmentsRepository.findOne({
      where: {
        doctorId: dto.doctorId,
        appointmentDate: dto.appointmentDate,
      },
      order: {
        queueNumber: 'DESC',
      },
    });

    const nextQueueNumber =
      lastAppointment && lastAppointment.queueNumber
        ? lastAppointment.queueNumber + 1
        : 1;

    // Create and save the appointment
    const appointment = this.appointmentsRepository.create({
      ...dto,
      userId,
      status: 'pending',
      queueNumber: nextQueueNumber,
    });

    const savedAppointment =
      await this.appointmentsRepository.save(appointment);

    // 1. Enqueue directly into Redis ordered list
    await this.queueService.enqueueAppointment(
      dto.doctorId,
      savedAppointment.id,
    );

    // 2. Queue a job to process status changes automatically via Bull Queue
    await this.queueService.addAppointmentJob({
      appointmentId: savedAppointment.id,
      patientId: userId,
      queueNumber: nextQueueNumber,
    });

    return savedAppointment;
  }

  async getMyAppointments(userId: string): Promise<Appointment[]> {
    return this.appointmentsRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async getAllAppointments(): Promise<Appointment[]> {
    return this.appointmentsRepository.find({
      order: { createdAt: 'DESC' },
    });
  }

  async getAnalytics(): Promise<any[]> {
    await Promise.resolve();
    return [
      { hour: '09:00 AM', waitTime: 12 },
      { hour: '10:00 AM', waitTime: 18 },
      { hour: '11:00 AM', waitTime: 26 },
      { hour: '12:00 PM', waitTime: 32 },
      { hour: '01:00 PM', waitTime: 15 },
      { hour: '02:00 PM', waitTime: 22 },
      { hour: '03:00 PM', waitTime: 30 },
      { hour: '04:00 PM', waitTime: 20 },
      { hour: '05:00 PM', waitTime: 8 },
    ];
  }

  async findOne(id: string): Promise<Appointment | null> {
    return this.appointmentsRepository.findOne({ where: { id } });
  }

  async updateStatus(id: string, status: string): Promise<Appointment> {
    await this.appointmentsRepository.update(id, { status });
    const updated = await this.findOne(id);
    if (!updated) {
      throw new Error(`Appointment with ID ${id} not found`);
    }
    return updated;
  }

  // Record patient check-in arrival
  async checkIn(appointmentId: string): Promise<Appointment> {
    const appointment = await this.findOne(appointmentId);
    if (!appointment) {
      throw new NotFoundException(
        `Appointment with ID ${appointmentId} not found`,
      );
    }

    appointment.arrivedAt = new Date();

    // Once arrived, they are active in the clinic queue
    if (appointment.status === 'pending') {
      appointment.status = 'in_queue';
    }

    const saved = await this.appointmentsRepository.save(appointment);

    // Broadcast live update showing checked-in arrival state
    await this.queueService.broadcastQueueState(appointment.doctorId);

    return saved;
  }
}
