import { IsNotEmpty, IsNumber, IsOptional, IsString } from 'class-validator';

export class BookAppointmentDto {
  @IsString()
  @IsNotEmpty()
  clinicId: string;

  @IsString()
  @IsNotEmpty()
  clinicName: string;

  @IsString()
  @IsNotEmpty()
  doctorId: string;

  @IsString()
  @IsNotEmpty()
  doctorName: string;

  @IsString()
  @IsNotEmpty()
  doctorSpecialty: string;

  @IsString()
  @IsNotEmpty()
  appointmentTime: string;

  @IsString()
  @IsNotEmpty()
  appointmentDate: string;

  @IsNumber()
  @IsOptional()
  lastLatitude?: number;

  @IsNumber()
  @IsOptional()
  lastLongitude?: number;

  @IsString()
  @IsOptional()
  fcmToken?: string;
}
