import express from 'express';
import { DefaultAzureCredential } from "@azure/identity";
import { BillingManagementClient } from "@azure/arm-billing";
import { ResourceManagementClient } from "@azure/arm-resources";
import { ManagementGroupsAPI } from "@azure/arm-managementgroups";
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { fileURLToPath } from 'url';

const router = express.Router();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Home page - Show enrollment accounts
router.get('/', async (req, res) => {
  try {
    const client = new BillingManagementClient(new DefaultAzureCredential());
    
    // Get billing account
    let billingAccountName;
    let enrollmentAccounts = [];
    
    for await (const account of client.billingAccounts.list()) {
      billingAccountName = account.name;
      break;
    }
    
    // Get enrollment accounts
    for await (const enrollmentAccount of client.enrollmentAccounts.listByBillingAccount(billingAccountName)) {
      enrollmentAccounts.push({
        id: enrollmentAccount.id,
        name: enrollmentAccount.properties.displayName
      });
    }
    
    res.render('home', { 
      enrollmentAccounts,
      title: 'Azure Subscription Creator'
    });
  } catch (error) {
    res.render('error', { 
      message: 'Error fetching enrollment accounts', 
      error: error.message,
      title: 'Error'
    });
  }
});

// Show management groups after enrollment account is selected
router.post('/management-groups', async (req, res) => {
  try {
    const enrollmentAccountId = req.body.enrollmentAccountId;
    const enrollmentAccountName = req.body.enrollmentAccountName;
    
    const managementGroupsClient = new ManagementGroupsAPI(new DefaultAzureCredential());
    let managementGroups = [];
    
    for await (const mg of managementGroupsClient.managementGroups.list()) {
      managementGroups.push({
        id: mg.name,
        name: mg.displayName || mg.name
      });
    }
    
    res.render('management-groups', { 
      managementGroups,
      enrollmentAccountId,
      enrollmentAccountName,
      title: 'Select Management Group'
    });
  } catch (error) {
    res.render('error', { 
      message: 'Error fetching management groups', 
      error: error.message,
      title: 'Error'
    });
  }
});

// Show confirmation page
router.post('/confirm', async (req, res) => {
  try {
    const { 
      enrollmentAccountId, 
      enrollmentAccountName,
      managementGroupId, 
      managementGroupName 
    } = req.body;
    
    const newSubscriptionName = crypto.randomUUID();
    const newSubscriptionDisplayName = req.body.subscriptionDisplayName || 'New Subscription';
    
    res.render('confirm', {
      enrollmentAccountId,
      enrollmentAccountName,
      managementGroupId,
      managementGroupName,
      newSubscriptionName,
      newSubscriptionDisplayName,
      title: 'Confirm Subscription Creation'
    });
  } catch (error) {
    res.render('error', { 
      message: 'Error preparing confirmation', 
      error: error.message,
      title: 'Error' 
    });
  }
});

// Create subscription
router.post('/create', async (req, res) => {
  // Generate a deployment name based on the current date and time
  const deploymentName = `deployment-${new Date().toISOString().replaceAll(':', '-')}`;
  
  const { 
    enrollmentAccountId, 
    managementGroupId,
    newSubscriptionName,
    newSubscriptionDisplayName 
  } = req.body;
  
  // Fallback subscription ID - this is required by the SDK but not needed for the operation
  const subscriptionId = "96ff2809-c950-4a50-9eb6-f26f23d32735";
  const resourceClient = new ResourceManagementClient(new DefaultAzureCredential(), subscriptionId);
  
  // Read ARM template
  const templatePath = path.join(process.cwd(), 'bicep', 'main.json');
  const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
  
  // Deploy the template
  const result = await resourceClient.deployments.beginCreateOrUpdateAtTenantScope(
    deploymentName,
    {
      location: "westeurope",
      properties: {
        mode: "Incremental",
        template,
        parameters: {
          billingScope: { value: enrollmentAccountId },
          subscriptionName: { value: newSubscriptionName },
          subscriptionDisplayName: { value: newSubscriptionDisplayName },
          managementGroupId: { value: managementGroupId }
        }
      }
    }
  );
  
  try {
    // Wait for deployment to complete
    const deployment = await result.pollUntilDone();
    
    // Get deployment operations for details
    let operations = [];
    for await (const op of resourceClient.deploymentOperations.listAtTenantScope(deploymentName)) {
      operations.push(op);
    }
    
    // Render result
    res.render('result', {
      title: 'Subscription Created',
      deployment: JSON.stringify(deployment, null, 2),
      operations: JSON.stringify(operations, null, 2),
      success: true
    });
  } catch (error) {
    console.log("Deployment failed:", error.message);
    
    // Get deployment operations for error details
    let operations = [];
    for await (const op of resourceClient.deploymentOperations.listAtTenantScope(deploymentName)) {
      operations.push(op);
    }
    
    res.render('error', { 
      message: 'Error creating subscription', 
      error: error.message,
      operations: JSON.stringify(operations, null, 2),
      title: 'Error',
      hasOperations: operations.length > 0
    });
  }
});

export default router; 