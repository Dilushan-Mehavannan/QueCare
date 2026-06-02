import { Entity, Column, PrimaryColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Clinic } from './clinic.entity';

@Entity('doctors')
export class Doctor {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ default: 'General Practitioner' })
  specialty: string;

  @Column({
    default:
      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&auto=format&fit=crop',
  })
  imageUrl: string;

  @Column('float', { default: 4.8 })
  rating: number;

  @Column('int', { default: 5 })
  experienceYears: number;

  @Column('simple-json', { nullable: true })
  availableSlots: string[];

  @ManyToOne(() => Clinic, (clinic) => clinic.doctors, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'clinicId' })
  clinic: Clinic;

  @Column()
  clinicId: string;
}
