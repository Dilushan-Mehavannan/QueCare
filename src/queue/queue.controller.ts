import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { QueueService } from './queue.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('queue')
@UseGuards(FirebaseAuthGuard)
export class QueueController {
  constructor(private queueService: QueueService) {}

  @Get(':appointmentId/status')
  async getStatus(@Param('appointmentId') appointmentId: string) {
    return this.queueService.getQueueStatus(appointmentId);
  }

  @Post(':doctorId/advance')
  async advanceQueue(@Param('doctorId') doctorId: string) {
    const completedAptId = await this.queueService.advanceQueue(doctorId);
    return { success: true, completedAppointmentId: completedAptId };
  }

  @Post(':doctorId/skip/:appointmentId')
  async skipAppointment(
    @Param('doctorId') doctorId: string,
    @Param('appointmentId') appointmentId: string,
  ) {
    await this.queueService.skipAppointment(doctorId, appointmentId);
    return { success: true };
  }
}
