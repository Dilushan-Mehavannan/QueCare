import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('appointments')
export class Appointment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  doctorId: string;

  @Column()
  doctorName: string;

  @Column()
  doctorSpecialty: string;

  @Column()
  clinicId: string;

  @Column()
  clinicName: string;

  @Column()
  appointmentTime: string;

  @Column()
  appointmentDate: string;

  @Column({ default: 'pending' })
  status: string; // 'pending' | 'in_queue' | 'completed' | 'cancelled'

  @Column('int', { nullable: true })
  queueNumber: number;

  @Column({ type: 'timestamp', nullable: true })
  arrivedAt: Date;

  @Column()
  userId: string;

  @Column('float', { nullable: true })
  lastLatitude: number;

  @Column('float', { nullable: true })
  lastLongitude: number;

  @Column({ nullable: true })
  fcmToken: string;

  @ManyToOne(() => User, (user) => user.appointments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @CreateDateColumn()
  createdAt: Date;
}
