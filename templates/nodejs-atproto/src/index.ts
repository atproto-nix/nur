import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { createXrpcServer } from '@atproto/xrpc-server';
import { lexicons } from '@atproto/lexicon';
import winston from 'winston';
import dotenv from 'dotenv';
import { z } from 'zod';

// Load environment variables
dotenv.config();

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Configuration schema
const configSchema = z.object({
  port: z.number().default(3000),
  host: z.string().default('localhost'),
  logLevel: z.string().default('info'),
  // Add your configuration options here
});

type Config = z.infer<typeof configSchema>;

// Parse configuration
const config: Config = configSchema.parse({
  port: parseInt(process.env.PORT || '3000'),
  host: process.env.HOST || 'localhost',
  logLevel: process.env.LOG_LEVEL || 'info',
});

// ATProto request/response types
interface AtprotoRequest {
  did: string;
  collection: string;
  record?: any;
}

interface AtprotoResponse {
  success: boolean;
  uri?: string;
  cid?: string;
  message?: string;
}

// Health check endpoint
interface HealthResponse {
  status: string;
  version: string;
  timestamp: string;
}

class AtprotoService {
  private app: express.Application;
  private xrpc: any;

  constructor() {
    this.app = express();
    this.setupMiddleware();
    this.setupXrpc();
    this.setupRoutes();
  }

  private setupMiddleware(): void {
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(compression());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));

    // Request logging
    this.app.use((req, res, next) => {
      logger.info(`${req.method} ${req.path}`, {
        method: req.method,
        path: req.path,
        userAgent: req.get('User-Agent'),
        ip: req.ip
      });
      next();
    });
  }

  private setupXrpc(): void {
    // Create XRPC server for ATProto methods
    this.xrpc = createXrpcServer(lexicons.schemas);

    // Add your ATProto method handlers here
    this.xrpc.method('com.atproto.repo.createRecord', this.handleCreateRecord.bind(this));
    this.xrpc.method('com.atproto.repo.getRecord', this.handleGetRecord.bind(this));
    // Add more methods as needed
  }

  private setupRoutes(): void {
    // Health check endpoint
    this.app.get('/health', this.handleHealth.bind(this));

    // XRPC endpoints
    this.app.use('/xrpc', this.xrpc.router);

    // Error handling
    this.app.use(this.errorHandler.bind(this));
  }

  private async handleHealth(req: express.Request, res: express.Response): Promise<void> {
    const response: HealthResponse = {
      status: 'healthy',
      version: process.env.npm_package_version || '0.1.0',
      timestamp: new Date().toISOString()
    };

    res.json(response);
  }

  private async handleCreateRecord(ctx: any): Promise<AtprotoResponse> {
    const { did, collection, record } = ctx.input.body as AtprotoRequest;

    logger.info('Creating record', { did, collection });

    try {
      // TODO: Implement your record creation logic here
      // This is where you would:
      // 1. Validate the DID and authentication
      // 2. Validate the record against the lexicon
      // 3. Store the record in your database
      // 4. Return the appropriate response

      // Placeholder implementation
      const uri = `at://${did}/${collection}/placeholder`;
      const cid = 'bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua'; // placeholder CID

      return {
        success: true,
        uri,
        cid
      };
    } catch (error) {
      logger.error('Failed to create record', { error, did, collection });
      throw error;
    }
  }

  private async handleGetRecord(ctx: any): Promise<any> {
    const { repo, collection, rkey } = ctx.params;

    logger.info('Getting record', { repo, collection, rkey });

    try {
      // TODO: Implement your record retrieval logic here
      // This is where you would:
      // 1. Validate the parameters
      // 2. Retrieve the record from your database
      // 3. Return the record data

      // Placeholder implementation
      return {
        uri: `at://${repo}/${collection}/${rkey}`,
        cid: 'bafyreigbtj4x7ip5legnfznufuopl4sg4knzc2cof6duas4b3q2fy6swua',
        value: {
          text: 'Hello ATProto!',
          createdAt: new Date().toISOString()
        }
      };
    } catch (error) {
      logger.error('Failed to get record', { error, repo, collection, rkey });
      throw error;
    }
  }

  private errorHandler(
    err: Error,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ): void {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });

    res.status(500).json({
      error: 'Internal Server Error',
      message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
  }

  public async start(): Promise<void> {
    return new Promise((resolve) => {
      this.app.listen(config.port, config.host, () => {
        logger.info(`ATProto service listening on ${config.host}:${config.port}`);
        resolve();
      });
    });
  }
}

// Start the service
async function main(): Promise<void> {
  try {
    const service = new AtprotoService();
    await service.start();
  } catch (error) {
    logger.error('Failed to start service', { error });
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
  logger.info('Received SIGINT, shutting down gracefully');
  process.exit(0);
});

process.on('SIGTERM', () => {
  logger.info('Received SIGTERM, shutting down gracefully');
  process.exit(0);
});

if (require.main === module) {
  main().catch((error) => {
    logger.error('Fatal error', { error });
    process.exit(1);
  });
}

export { AtprotoService, config };