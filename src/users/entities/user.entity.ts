import {
  Entity,
  Column,
  PrimaryColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Appointment } from '../../appointments/entities/appointment.entity';

@Entity('users')
export class User {
  @PrimaryColumn()
  id: string; // Firebase UID

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @Column({ default: 'patient' })
  role: string; // 'patient' | 'doctor' | 'admin'

  @OneToMany(() => Appointment, (appointment) => appointment.user)
  appointments: Appointment[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
