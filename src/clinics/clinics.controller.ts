import { Controller, Get, Param } from '@nestjs/common';
import { ClinicsService } from './clinics.service';
import { Clinic } from './entities/clinic.entity';
import { Doctor } from './entities/doctor.entity';

@Controller('clinics')
export class ClinicsController {
  constructor(private clinicsService: ClinicsService) {}

  @Get()
  async findAll(): Promise<Clinic[]> {
    return this.clinicsService.findAll();
  }

  @Get(':id/doctors')
  async findDoctors(@Param('id') id: string): Promise<Doctor[]> {
    return this.clinicsService.findDoctorsByClinicId(id);
  }
}
