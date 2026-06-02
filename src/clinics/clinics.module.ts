import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClinicsController } from './clinics.controller';
import { ClinicsService } from './clinics.service';
import { Clinic } from './entities/clinic.entity';
import { Doctor } from './entities/doctor.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Clinic, Doctor])],
  controllers: [ClinicsController],
  providers: [ClinicsService],
  exports: [ClinicsService, TypeOrmModule],
})
export class ClinicsModule {}
