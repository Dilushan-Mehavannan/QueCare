import { Entity, Column, PrimaryColumn, OneToMany } from 'typeorm';
import { Doctor } from './doctor.entity';

@Entity('clinics')
export class Clinic {
  @PrimaryColumn()
  id: string;

  @Column()
  name: string;

  @Column({ default: 'General Clinic' })
  specialty: string;

  @Column()
  address: string;

  @Column({
    default:
      'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=500&auto=format&fit=crop',
  })
  imageUrl: string;

  @Column('float', { default: 4.5 })
  rating: number;

  @Column({ default: '1.2 km' })
  distance: string;

  @OneToMany(() => Doctor, (doctor) => doctor.clinic, {
    cascade: true,
    eager: true,
  })
  doctors: Doctor[];
}
