import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  fullName: string;

  @Prop({ required: true, unique: true, lowercase: true })
  email: string;

  @Prop()
  passwordHash?: string;

  @Prop()
  passwordSalt?: string;

  @Prop({ type: String, enum: ['local', 'google'], default: 'local' })
  authProvider!: 'local' | 'google';

  @Prop({ unique: true, sparse: true })
  googleSub?: string;

  @Prop()
  phoneCipherText?: string;

  @Prop()
  phoneIv?: string;

  @Prop()
  phoneAuthTag?: string;
}

export const UserSchema = SchemaFactory.createForClass(User);
