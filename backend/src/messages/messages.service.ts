import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CryptoService } from '../common/crypto/crypto.service';
import { Group, GroupDocument } from '../groups/group.schema';
import { User, UserDocument } from '../users/user.schema';
import { CreateDirectMessageDto } from './create-direct-message.dto';
import { CreateGroupMessageDto } from './create-group-message.dto';
import { Message, MessageDocument } from './message.schema';

@Injectable()
export class MessagesService {
  constructor(
    @InjectModel(Message.name) private readonly messageModel: Model<MessageDocument>,
    @InjectModel(User.name) private readonly userModel: Model<UserDocument>,
    @InjectModel(Group.name) private readonly groupModel: Model<GroupDocument>,
    private readonly cryptoService: CryptoService,
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

    return {
      id: createdMessage.id,
      messageType: createdMessage.messageType,
      senderId: createdMessage.senderId,
      receiverUserId: createdMessage.receiverUserId,
      content: createDirectMessageDto.content,
      createdAt: createdMessage.createdAt,
    };
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

    return {
      id: createdMessage.id,
      messageType: createdMessage.messageType,
      senderId: createdMessage.senderId,
      groupId: createdMessage.groupId,
      content: createGroupMessageDto.content,
      createdAt: createdMessage.createdAt,
    };
  }

  async getDirectConversation(userAId: string, userBId: string) {
    const messages = await this.messageModel
      .find({
        messageType: 'direct',
        $or: [
          { senderId: new Types.ObjectId(userAId), receiverUserId: new Types.ObjectId(userBId) },
          { senderId: new Types.ObjectId(userBId), receiverUserId: new Types.ObjectId(userAId) },
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
      createdAt: message.createdAt,
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
      createdAt: message.createdAt,
    }));
  }
}
