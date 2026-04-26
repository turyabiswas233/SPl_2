import { PrismaPg } from '@prisma/adapter-pg'
import path from 'path'
import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default {
  schema: path.resolve(__dirname, 'schema.prisma'),
  datasource: {
    adapter: new PrismaPg(),
  },
}