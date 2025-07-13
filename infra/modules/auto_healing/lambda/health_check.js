const AWS = require('aws-sdk');

exports.handler = async (event) => {
    const ec2 = new AWS.EC2();
    const elbv2 = new AWS.ELBv2();
    const sns = new AWS.SNS();
    
    const instanceIds = JSON.parse(process.env.INSTANCE_IDS);
    const targetGroupArn = process.env.TARGET_GROUP_ARN;
    const snsTopicArn = process.env.SNS_TOPIC_ARN;
    
    try {
        // Check EC2 instance status
        const instanceStatus = await ec2.describeInstanceStatus({
            InstanceIds: instanceIds
        }).promise();
        
        // Check target group health
        const targetHealth = await elbv2.describeTargetHealth({
            TargetGroupArn: targetGroupArn
        }).promise();
        
        // Process health check results
        const unhealthyInstances = instanceStatus.InstanceStatuses.filter(
            status => status.InstanceStatus.Status !== 'ok' || 
                     status.SystemStatus.Status !== 'ok'
        );
        
        const unhealthyTargets = targetHealth.TargetHealthDescriptions.filter(
            target => target.TargetHealth.State !== 'healthy'
        );
        
        if (unhealthyInstances.length > 0 || unhealthyTargets.length > 0) {
            await sns.publish({
                TopicArn: snsTopicArn,
                Subject: 'Health Check Alert',
                Message: JSON.stringify({
                    unhealthyInstances,
                    unhealthyTargets,
                    timestamp: new Date().toISOString()
                }, null, 2)
            }).promise();
        }
        
        return {
            statusCode: 200,
            body: 'Health check completed'
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
};
