import { Controller, Get, Header } from '@nestjs/common';
import { register } from 'prom-client';
import { MetricsService } from 'src/metrics/metrics.service';

@Controller('metrics')
export class MetricsController {
  constructor(private readonly metricsService: MetricsService) {}
  @Get()
  @Header('content-type', register.contentType)
  async getMetrics() {
    return await this.metricsService.getMetrics();
  }
}
