import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { AppointmentsService } from './appointments.service';
import { BookAppointmentDto } from './dto/book-appointment.dto';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { GetUser } from '../auth/get-user.decorator';

@Controller('appointments')
@UseGuards(FirebaseAuthGuard)
export class AppointmentsController {
  constructor(private appointmentsService: AppointmentsService) {}

  @Post('book')
  async book(@GetUser('uid') userId: string, @Body() dto: BookAppointmentDto) {
    return this.appointmentsService.bookAppointment(userId, dto);
  }

  @Post(':id/checkin')
  async checkIn(@Param('id') id: string) {
    return this.appointmentsService.checkIn(id);
  }

  @Get('my')
  async getMy(@GetUser('uid') userId: string) {
    return this.appointmentsService.getMyAppointments(userId);
  }

  @Get('all')
  async getAll() {
    return this.appointmentsService.getAllAppointments();
  }

  @Get('analytics')
  async getAnalytics() {
    return this.appointmentsService.getAnalytics();
  }

  // Fallback GET /appointments for mobile provider compatibility
  @Get()
  async getFallback(@GetUser('uid') userId: string) {
    return this.appointmentsService.getMyAppointments(userId);
  }
}
