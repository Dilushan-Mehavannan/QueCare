import { Process, Processor } from '@nestjs/bull';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as Bull from 'bull';
import { Appointment } from '../appointments/entities/appointment.entity';

@Processor('queue')
export class QueueProcessor {
  constructor(
    @InjectRepository(Appointment)
    private appointmentsRepository: Repository<Appointment>,
  ) {}

  @Process('process-appointment')
  async handleAppointment(job: Bull.Job) {
    const { appointmentId } = job.data as { appointmentId: string };
    console.log(
      `[QueueProcessor] Asynchronously processing appointment ${appointmentId}...`,
    );

    // Simulate queue scheduling latency
    await new Promise((resolve) => setTimeout(resolve, 3000));

    const appointment = await this.appointmentsRepository.findOne({
      where: { id: appointmentId },
    });
    if (appointment && appointment.status === 'pending') {
      appointment.status = 'in_queue';
      await this.appointmentsRepository.save(appointment);
      console.log(
        `[QueueProcessor] Appointment ${appointmentId} successfully moved to 'in_queue' status.`,
      );
    }
  }
}
