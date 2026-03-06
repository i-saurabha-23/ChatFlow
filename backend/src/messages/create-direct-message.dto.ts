import { IsMongoId, IsString, MinLength } from 'class-validator';

export class CreateDirectMessageDto {
  @IsMongoId()
  senderId: string;

  @IsMongoId()
  receiverUserId: string;

  @IsString()
  @MinLength(1)
  content: string;
}
