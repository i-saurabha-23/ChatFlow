import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { CreateDirectMessageDto } from './create-direct-message.dto';
import { CreateGroupMessageDto } from './create-group-message.dto';
import { MessagesService } from './messages.service';

@Controller('messages')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Post('direct')
  async createDirectMessage(@Body() createDirectMessageDto: CreateDirectMessageDto) {
    return this.messagesService.createDirectMessage(createDirectMessageDto);
  }

  @Post('group')
  async createGroupMessage(@Body() createGroupMessageDto: CreateGroupMessageDto) {
    return this.messagesService.createGroupMessage(createGroupMessageDto);
  }

  @Get('direct/:userAId/:userBId')
  async getDirectConversation(
    @Param('userAId') userAId: string,
    @Param('userBId') userBId: string,
  ) {
    return this.messagesService.getDirectConversation(userAId, userBId);
  }

  @Get('group/:groupId')
  async getGroupConversation(@Param('groupId') groupId: string) {
    return this.messagesService.getGroupConversation(groupId);
  }
}
