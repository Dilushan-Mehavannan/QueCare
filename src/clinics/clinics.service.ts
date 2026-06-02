import {
  Injectable,
  OnApplicationBootstrap,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Clinic } from './entities/clinic.entity';
import { Doctor } from './entities/doctor.entity';

@Injectable()
export class ClinicsService implements OnApplicationBootstrap {
  constructor(
    @InjectRepository(Clinic)
    private clinicsRepository: Repository<Clinic>,
    @InjectRepository(Doctor)
    private doctorsRepository: Repository<Doctor>,
  ) {}

  async onApplicationBootstrap() {
    await this.seed();
  }

  async findAll(): Promise<Clinic[]> {
    return this.clinicsRepository.find({ relations: ['doctors'] });
  }

  async findOne(id: string): Promise<Clinic> {
    const clinic = await this.clinicsRepository.findOne({
      where: { id },
      relations: ['doctors'],
    });
    if (!clinic) {
      throw new NotFoundException(`Clinic with ID ${id} not found`);
    }
    return clinic;
  }

  async findDoctorsByClinicId(clinicId: string): Promise<Doctor[]> {
    const clinic = await this.findOne(clinicId);
    return clinic.doctors;
  }

  async seed() {
    const count = await this.clinicsRepository.count();
    if (count > 0) {
      console.log('Database already has clinics data. Skipping seeding.');
      return;
    }

    console.log('Seeding clinics and doctors mock data...');

    // Clinic 1
    const clinic1 = new Clinic();
    clinic1.id = '1';
    clinic1.name = 'Metro Care General Hospital';
    clinic1.specialty = 'General Clinic';
    clinic1.address = '123 Healthcare Ave, Downtown';
    clinic1.imageUrl =
      'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=500&auto=format&fit=crop';
    clinic1.rating = 4.7;
    clinic1.distance = '1.2 km';

    const d1 = new Doctor();
    d1.id = 'd1';
    d1.name = 'Dr. Sarah Jenkins';
    d1.specialty = 'General Practitioner';
    d1.imageUrl =
      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&auto=format&fit=crop';
    d1.rating = 4.9;
    d1.experienceYears = 8;
    d1.availableSlots = [
      '09:00 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '02:00 PM',
      '03:30 PM',
    ];

    const d2 = new Doctor();
    d2.id = 'd2';
    d2.name = 'Dr. Marcus Vance';
    d2.specialty = 'Cardiologist';
    d2.imageUrl =
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&auto=format&fit=crop';
    d2.rating = 4.8;
    d2.experienceYears = 12;
    d2.availableSlots = ['10:00 AM', '11:30 AM', '01:00 PM', '04:00 PM'];

    clinic1.doctors = [d1, d2];
    await this.clinicsRepository.save(clinic1);

    // Clinic 2
    const clinic2 = new Clinic();
    clinic2.id = '2';
    clinic2.name = 'Apex Dental & Orthodontics';
    clinic2.specialty = 'Dental Clinic';
    clinic2.address = '456 Smiles Blvd, Suite A';
    clinic2.imageUrl =
      'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=500&auto=format&fit=crop';
    clinic2.rating = 4.6;
    clinic2.distance = '2.5 km';

    const d3 = new Doctor();
    d3.id = 'd3';
    d3.name = 'Dr. Elena Rostova';
    d3.specialty = 'Pediatric Dentist';
    d3.imageUrl =
      'https://images.unsplash.com/photo-1594824813573-246434de83fb?w=400&auto=format&fit=crop';
    d3.rating = 4.7;
    d3.experienceYears = 6;
    d3.availableSlots = [
      '09:30 AM',
      '11:00 AM',
      '01:00 PM',
      '02:30 PM',
      '05:00 PM',
    ];

    clinic2.doctors = [d3];
    await this.clinicsRepository.save(clinic2);

    console.log('Seeding completed successfully!');
  }
}
