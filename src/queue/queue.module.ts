import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { TypeOrmModule } from '@nestjs/typeorm';
import { QueueController } from './queue.controller';
import { QueueService } from './queue.service';
import { QueueProcessor } from './queue.processor';
import { NoShowProcessor } from './no-show.processor';
import { RedisProvider } from './redis.provider';
import { QueueGateway } from './queue.gateway';
import { AuthModule } from '../auth/auth.module';
import { Appointment } from '../appointments/entities/appointment.entity';

@Module({
  imports: [
    BullModule.registerQueue({
      name: 'queue',
    }),
    TypeOrmModule.forFeature([Appointment]),
    AuthModule,
  ],
  controllers: [QueueController],
  providers: [
    QueueService,
    QueueProcessor,
    NoShowProcessor,
    RedisProvider,
    QueueGateway,
  ],
  exports: [QueueService, RedisProvider, QueueGateway],
})
export class QueueModule {}
