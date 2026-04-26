// Custom Prisma config using PostgreSQL for development
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: './prisma/schema.prisma',
  datasource: {
    url: 'postgresql://postgres:pass@localhost:5432/dromos',
  },
});