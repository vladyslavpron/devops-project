import { Injectable } from '@nestjs/common';
import { MetricsService } from 'src/metrics/metrics.service';

@Injectable()
export class AppService {
  constructor(private readonly metricsService: MetricsService) {}
  async getHello(): Promise<string> {
    this.metricsService.incrementMyMetricCounter();

    return 'Hello 🥰!';
  }
}
