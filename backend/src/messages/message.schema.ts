import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type MessageDocument = HydratedDocument<Message>;

@Schema({ timestamps: true })
export class Message {
  @Prop({ required: true, enum: ['direct', 'group'] })
  messageType: 'direct' | 'group';

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  senderId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User' })
  receiverUserId?: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Group' })
  groupId?: Types.ObjectId;

  @Prop({ required: true })
  cipherText: string;

  @Prop({ required: true })
  iv: string;

  @Prop({ required: true })
  authTag: string;
}

export const MessageSchema = SchemaFactory.createForClass(Message);
