import { App, TerraformOutput, TerraformStack } from 'cdktf';
import { Construct } from 'constructs';
import { Alb } from './alb';
import { Backup } from './backup';
import { Ecs } from './ecs';
import { Monitoring } from './monitoring';
import { Networking } from './networking';
import { Rds } from './rds';

class ProdEStack extends TerraformStack {
  constructor(scope: Construct, id: string) {
    super(scope, id);

    const networking = new Networking(this, 'networking');
    const alb = new Alb(this, 'alb', networking);
    const ecs = new Ecs(this, 'ecs', networking, alb);
    const rds = new Rds(this, 'rds', networking);
    const monitoring = new Monitoring(this, 'monitoring', networking, alb, ecs);
    const backup = new Backup(this, 'backup');

    // Outputs
    new TerraformOutput(this, 'alb_endpoint', {
      value: alb.alb.dnsName,
    });
  }
}

const app = new App();
new ProdEStack(app, 'prod-e');
app.synth();
