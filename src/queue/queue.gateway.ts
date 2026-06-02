import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class QueueGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`[QueueGateway] Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`[QueueGateway] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('subscribeToDoctor')
  async handleSubscribeToDoctor(client: Socket, payload: { doctorId: string }) {
    const room = `doctor:${payload.doctorId}`;
    await client.join(room);
    console.log(`[QueueGateway] Socket ${client.id} joined room ${room}`);
    return {
      status: 'success',
      message: `Subscribed to doctor ${payload.doctorId}`,
    };
  }

  @SubscribeMessage('unsubscribeFromDoctor')
  async handleUnsubscribeFromDoctor(
    client: Socket,
    payload: { doctorId: string },
  ) {
    const room = `doctor:${payload.doctorId}`;
    await client.leave(room);
    console.log(`[QueueGateway] Socket ${client.id} left room ${room}`);
    return {
      status: 'success',
      message: `Unsubscribed from doctor ${payload.doctorId}`,
    };
  }

  emitQueueUpdate(doctorId: string, updateData: any) {
    const room = `doctor:${doctorId}`;
    console.log(
      `[QueueGateway] Broadcasting queue update to room ${room}:`,
      updateData,
    );
    if (this.server) {
      this.server.to(room).emit('queue-update', updateData);
    }
  }
}
