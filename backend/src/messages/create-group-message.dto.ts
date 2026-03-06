import { IsMongoId, IsString, MinLength } from 'class-validator';

export class CreateGroupMessageDto {
  @IsMongoId()
  senderId: string;

  @IsMongoId()
  groupId: string;

  @IsString()
  @MinLength(1)
  content: string;
}
