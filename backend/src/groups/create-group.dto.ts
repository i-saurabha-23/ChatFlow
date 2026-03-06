import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsMongoId,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

export class CreateGroupDto {
  @IsString()
  @MinLength(2)
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsMongoId()
  adminId: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsMongoId({ each: true })
  @Type(() => String)
  memberIds: string[];
}
