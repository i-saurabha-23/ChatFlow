import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CryptoService } from '../common/crypto/crypto.service';
import { Group, GroupDocument } from '../groups/group.schema';
import { NotificationsService } from '../notifications/notifications.service';
import { User, UserDocument } from '../users/user.schema';
import { CreateDirectMessageDto } from './create-direct-message.dto';
import { CreateGroupMessageDto } from './create-group-message.dto';
import {
  MessagesGateway,
  RealtimeChatMessageEvent,
} from './messages.gateway';
import { Message, MessageDocument } from './message.schema';

@Injectable()
export class MessagesService {
  constructor(
    @InjectModel(Message.name) private readonly messageModel: Model<MessageDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Group.name) private readonly groupModel: Model<GroupDocument>,
    private readonly cryptoService: CryptoService,
    private readonly messagesGateway: MessagesGateway,
    private readonly notificationsService: NotificationsService,
  ) {}

  async createDirectMessage(createDirectMessageDto: CreateDirectMessageDto) {
    const sender = await this.userModel.findById(createDirectMessageDto.senderId);
    const receiver = await this.userModel.findById(
      createDirectMessageDto.receiverUserId,
    );

    if (!sender || !receiver) {
      throw new NotFoundException('Sender or receiver user not found.');
    }

    const encrypted = this.cryptoService.encryptText(createDirectMessageDto.content);

    const createdMessage = await this.messageModel.create({
      messageType: 'direct',
      senderId: new Types.ObjectId(createDirectMessageDto.senderId),
      receiverUserId: new Types.ObjectId(createDirectMessageDto.receiverUserId),
      cipherText: encrypted.cipherText,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
    });

    const createdAt: Date = (createdMessage as any).createdAt ?? new Date();
    const senderId = sender.id;
    const receiverId = receiver.id;

    const response = {
      id: createdMessage.id,
      messageType: createdMessage.messageType,
      senderId: createdMessage.senderId,
      receiverUserId: createdMessage.receiverUserId,
      content: createDirectMessageDto.content,
      createdAt,
    };

    const realtimePayload: RealtimeChatMessageEvent = {
      id: createdMessage.id,
      messageType: 'direct',
      senderId,
      senderName: sender.fullName,
      receiverUserId: receiverId,
      receiverName: receiver.fullName,
      content: createDirectMessageDto.content,
      createdAt,
    };

    this.messagesGateway.broadcastMessageToUsers(
      [senderId, receiverId],
      realtimePayload,
    );

    await this.notificationsService.sendPushNotification({
      tokens: receiver.fcmTokens ?? [],
      title: sender.fullName,
      body: createDirectMessageDto.content,
      data: this.toPushData({
        id: createdMessage.id,
        messageType: 'direct',
        senderId,
        senderName: sender.fullName,
        receiverUserId: receiverId,
        receiverName: receiver.fullName,
        content: createDirectMessageDto.content,
        threadId: `d-${senderId}`,
        createdAt: createdAt.toISOString(),
      }),
    });

    return response;
  }

  async createGroupMessage(createGroupMessageDto: CreateGroupMessageDto) {
    const sender = await this.userModel.findById(createGroupMessageDto.senderId);

    if (!sender) {
      throw new NotFoundException('Sender user not found.');
    }

    const group = await this.groupModel.findById(createGroupMessageDto.groupId);

    if (!group) {
      throw new NotFoundException('Group not found.');
    }

    const isMember = group.memberIds.some(
      (memberId) => memberId.toString() === createGroupMessageDto.senderId,
    );

    if (!isMember) {
      throw new BadRequestException('Sender is not a member of this group.');
    }

    const encrypted = this.cryptoService.encryptText(createGroupMessageDto.content);

    const createdMessage = await this.messageModel.create({
      messageType: 'group',
      senderId: new Types.ObjectId(createGroupMessageDto.senderId),
      groupId: new Types.ObjectId(createGroupMessageDto.groupId),
      cipherText: encrypted.cipherText,
      iv: encrypted.iv,
      authTag: encrypted.authTag,
    });

    const createdAt: Date = (createdMessage as any).createdAt ?? new Date();
    const senderId = sender.id;
    const groupId = group.id;
    const memberIds = group.memberIds.map((memberId) => memberId.toString());

    const response = {
      id: createdMessage.id,
      messageType: createdMessage.messageType,
      senderId: createdMessage.senderId,
      groupId: createdMessage.groupId,
      content: createGroupMessageDto.content,
      createdAt,
    };

    const realtimePayload: RealtimeChatMessageEvent = {
      id: createdMessage.id,
      messageType: 'group',
      senderId,
      senderName: sender.fullName,
      groupId,
      groupName: group.name,
      content: createGroupMessageDto.content,
      createdAt,
    };

    this.messagesGateway.broadcastMessageToUsers(memberIds, realtimePayload);

    const recipientIds = memberIds.filter((memberId) => memberId !== senderId);
    const recipientUsers = await this.userModel
      .find({ _id: { $in: recipientIds.map((id) => new Types.ObjectId(id)) } })
      .select({ fcmTokens: 1 });

    const recipientTokens = recipientUsers.flatMap((user) => user.fcmTokens ?? []);

    await this.notificationsService.sendPushNotification({
      tokens: recipientTokens,
      title: `${sender.fullName} - ${group.name}`,
      body: createGroupMessageDto.content,
      data: this.toPushData({
        id: createdMessage.id,
        messageType: 'group',
        senderId,
        senderName: sender.fullName,
        groupId,
        groupName: group.name,
        content: createGroupMessageDto.content,
        threadId: `g-${groupId}`,
        createdAt: createdAt.toISOString(),
      }),
    });

    return response;
  }

  async getDirectConversation(userAId: string, userBId: string) {
    const messages = await this.messageModel
      .find({
        messageType: 'direct',
        $or: [
          {
            senderId: new Types.ObjectId(userAId),
            receiverUserId: new Types.ObjectId(userBId),
          },
          {
            senderId: new Types.ObjectId(userBId),
            receiverUserId: new Types.ObjectId(userAId),
          },
        ],
      })
      .sort({ createdAt: 1 });

    return messages.map((message) => ({
      id: message.id,
      messageType: message.messageType,
      senderId: message.senderId,
      receiverUserId: message.receiverUserId,
      content: this.cryptoService.decryptText({
        cipherText: message.cipherText,
        iv: message.iv,
        authTag: message.authTag,
      }),
      createdAt: (message as any).createdAt,
    }));
  }

  async getGroupConversation(groupId: string) {
    const group = await this.groupModel.findById(groupId);

    if (!group) {
      throw new NotFoundException('Group not found.');
    }

    const messages = await this.messageModel
      .find({
        messageType: 'group',
        groupId: new Types.ObjectId(groupId),
      })
      .sort({ createdAt: 1 });

    return messages.map((message) => ({
      id: message.id,
      messageType: message.messageType,
      senderId: message.senderId,
      groupId: message.groupId,
      content: this.cryptoService.decryptText({
        cipherText: message.cipherText,
        iv: message.iv,
        authTag: message.authTag,
      }),
      createdAt: (message as any).createdAt,
    }));
  }

  private toPushData(values: Record<string, string | undefined>): Record<string, string> {
    const entries = Object.entries(values)
      .filter((entry) => entry[1] != null && entry[1]!.trim().length > 0)
      .map((entry) => [entry[0], entry[1]!.trim()] as const);

    return Object.fromEntries(entries);
  }
}

