import { Logger } from '@nestjs/common';
import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

export interface RealtimeChatMessageEvent {
  id: string;
  messageType: 'direct' | 'group';
  senderId: string;
  senderName: string;
  receiverUserId?: string;
  receiverName?: string;
  groupId?: string;
  groupName?: string;
  content: string;
  createdAt: Date;
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class MessagesGateway {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(MessagesGateway.name);

  handleConnection(client: Socket) {
    const userId = this.extractUserIdFromHandshake(client);
    if (!userId) {
      return;
    }

    client.join(this.userRoom(userId));
  }

  @SubscribeMessage('chat:register')
  handleRegister(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { userId?: string },
  ) {
    const userId = body.userId?.trim();
    if (!userId) {
      return;
    }

    client.join(this.userRoom(userId));
    this.logger.log(`Socket ${client.id} registered for user ${userId}.`);
  }

  broadcastMessageToUsers(userIds: string[], payload: RealtimeChatMessageEvent) {
    const uniqueUserIds = Array.from(
      new Set(userIds.map((userId) => userId.trim()).filter((userId) => userId.length > 0)),
    );

    for (const userId of uniqueUserIds) {
      this.server.to(this.userRoom(userId)).emit('chat:message', payload);
    }
  }

  private extractUserIdFromHandshake(client: Socket): string | null {
    const rawUserId = client.handshake.query['userId'];

    if (typeof rawUserId !== 'string') {
      return null;
    }

    const userId = rawUserId.trim();
    return userId.length > 0 ? userId : null;
  }

  private userRoom(userId: string): string {
    return `user:${userId}`;
  }
}
