import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateFcmTokenDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(4096)
  token!: string;
}
