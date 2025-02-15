import { Injectable } from '@nestjs/common';
import { collectDefaultMetrics, Counter, register } from 'prom-client';

const myMetricCounter = new Counter({ name: 'my_counter', help: 'My counter' });
collectDefaultMetrics();
console.log(collectDefaultMetrics.metricsList);

@Injectable()
export class MetricsService {
  async getMetrics() {
    return await register.metrics();
  }

  incrementMyMetricCounter(value?: number) {
    myMetricCounter.inc(value);
  }
}
