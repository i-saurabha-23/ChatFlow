# ChatFlow Backend (NestJS + MongoDB)

## Setup

1. Go to backend directory:

```bash
cd backend
```

2. Install dependencies:

```bash
npm install
```

3. Copy env file and update values:

```bash
cp .env.example .env
```

- `MONGODB_URI`: Your MongoDB URL
- `MESSAGE_ENCRYPTION_KEY`: 64 character hex key (32 bytes)
- `GOOGLE_CLIENT_IDS`: Comma-separated Google OAuth client IDs that can sign in
- `FIREBASE_SERVICE_ACCOUNT_PATH`: Path to Firebase service account file (for FCM), e.g. `serviceAccountKey.json`

4. Run in development:

```bash
npm run start:dev
```

API base URL: `http://localhost:3000/api`

Mongo database name is fixed as: `chatflow`

## Endpoints

- `POST /api/users`
- `GET /api/users/:id`
- `POST /api/users/:id/fcm-token`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/google`
- `GET /api/auth/session`
- `POST /api/groups`
- `GET /api/groups/:id`
- `POST /api/messages/direct`
- `POST /api/messages/group`
- `GET /api/messages/direct/:userAId/:userBId`
- `GET /api/messages/group/:groupId`

WebSocket:
- Connect to server root (`ws://<host>:<port>`) and emit `chat:register` with `{ userId }`
- Listen for `chat:message` for real-time direct/group message events

## Security

- Message encryption: AES-256-GCM
- Phone number encryption: AES-256-GCM
- Password hashing: PBKDF2-SHA256 (120000 iterations + per-user salt)
